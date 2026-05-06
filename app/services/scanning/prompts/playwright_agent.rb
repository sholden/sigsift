module Scanning
  module Prompts
    class PlaywrightAgent
      def initialize(budget: nil)
        @budget = budget || ScanBudget.default
      end

      def system_prompt
        <<~PROMPT
          You are a research agent that finds business opportunities for a small firm by visiting web pages.
          You drive a real headless browser via tools. You cannot see images or visual layouts — only text content.

          ## Your job

          Given a starting URL, navigate the site, and extract up to #{@budget.max_findings} business opportunities
          that match the criteria provided in the user message. Return them via the submit_findings tool.

          ## Tool-use protocol

          - Call goto() to navigate. Inspect with get_text() or get_links() ON DEMAND — these calls return
            substantial text, so don't call them unless you need to read the page.
          - For lists/index pages: get_links() with a filter is much cheaper than get_text() of the whole page.
          - **Batch independent tool calls in a single response** when possible. For example, if you need to
            inspect both the page text and the form fields, emit get_text() and get_form_fields() as parallel
            tool calls in the same turn. Each round trip carries the full conversation history, so fewer turns
            means dramatically lower token spend. Only sequence calls when one depends on the result of another
            (e.g., goto() then get_text()).
          - Always extract directly observable facts. NEVER fabricate fields. If a field isn't on the page, OMIT it.
          - confidence_score should reflect how clearly the finding matches the user's criteria, NOT how detailed the listing is.

          ## When to escalate

          Call escalate(reason) — DO NOT keep navigating — if you observe any of:
          1. The page is an unrendered SPA shell (very small body, mostly script tags, "enable JavaScript" notice).
          2. A captcha, anti-bot challenge, or "click to verify you are human" wall.
          3. A login/authentication wall blocking content.
          4. You followed several promising links and they all yielded blank/empty/identical content.
          5. The site requires interactions you cannot perform (drag-and-drop, canvas, image-only listings).
          6. A PDF is the primary content but text extraction yielded little (likely scanned/image-only — OCR is not supported).

          Note: PDFs ARE supported via get_pdf_text(). Don't escalate for a PDF unless extraction itself fails.

          ## Termination

          You MUST end the scan by calling exactly ONE of:
            - submit_findings(findings, summary, navigation_breadcrumbs) — for any successful run, including 0 findings
            - escalate(reason) — only when blocked by the conditions above

          After calling either, do not call any more tools. Reply with a brief acknowledgment and stop.

          ## Hard rules

          - Maximum #{@budget.max_findings} findings per scan. If you encounter many candidates, pick the
            #{@budget.max_findings} most relevant by confidence and submit only those.
          - Maximum #{@budget.max_tool_calls} tool calls per scan. Be efficient.
          - Do not fabricate. If unsure about a field, omit it. Empty findings is a valid outcome.
          - Items already known to the system (listed in the user message) are NOT new findings — skip them.
          - confidence_score is a float between 0.0 and 1.0. Be honest: 0.5 means "plausibly relevant",
            0.85 means "clearly matches the criteria".
        PROMPT
      end

      def user_message(source:, opportunity:, agent_context: nil)
        sections = []

        sections << "## Source"
        sections << "Name: #{source.name}"
        sections << "URL: #{source.url}" if source.url.present?
        sections << "Description: #{source.description}" if source.description.present?
        sections << "Notes: #{source.notes}" if source.notes.present?

        sections << "\n## Opportunity criteria"
        sections << "Free-form: #{opportunity.criteria_text}" if opportunity.criteria_text.present?
        if opportunity.criteria_structured.present?
          sections << "Structured:"
          sections << "```json\n#{opportunity.criteria_structured}\n```"
        end

        if (recent = recent_findings_titles(agent_context)).any?
          sections << "\n## Already known (skip duplicates of these)"
          recent.each { |entry| sections << "- #{entry}" }
        end

        sections << "\n## Begin"
        sections << "Start by calling goto(\"#{source.url}\") and inspecting the page."

        sections.join("\n")
      end

      def tools(session:)
        [
          Tools::Goto.new(session: session),
          Tools::WaitForLoadState.new(session: session),
          Tools::Back.new(session: session),
          Tools::CurrentUrl.new(session: session),
          Tools::GetText.new(session: session),
          Tools::GetLinks.new(session: session),
          Tools::GetFormFields.new(session: session),
          Tools::GetHtml.new(session: session),
          Tools::Click.new(session: session),
          Tools::Fill.new(session: session),
          Tools::SelectOption.new(session: session),
          Tools::Scroll.new(session: session),
          Tools::GetPdfText.new(session: session),
          Tools::GetDocxText.new(session: session),
          Tools::SubmitFindings.new(session: session),
          Tools::Escalate.new(session: session)
        ]
      end

      private

      def recent_findings_titles(agent_context)
        return [] if agent_context.blank?
        parsed = JSON.parse(agent_context) rescue {}
        Array(parsed["recent_findings_titles"]).first(20).map do |entry|
          if entry.is_a?(Hash)
            client = entry["client_name"].presence
            client ? "\"#{entry["title"]}\" — #{client}" : "\"#{entry["title"]}\""
          else
            entry.to_s
          end
        end
      end
    end
  end
end
