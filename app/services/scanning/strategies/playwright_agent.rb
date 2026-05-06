require "playwright"

module Scanning
  module Strategies
    class PlaywrightAgent < Base
      def initialize(budget: nil, model: nil)
        @budget = budget || ScanBudget.default
        @model = model
      end

      def call(source:, opportunity:, previous_context: nil)
        Playwright.create(playwright_cli_executable_path: playwright_cli_path) do |playwright|
          browser = playwright.chromium.launch(headless: true)
          context = browser.new_context(userAgent: USER_AGENT)
          page = context.new_page

          run_with(page, source, opportunity, previous_context)
        ensure
          context&.close
          browser&.close
        end
      end

      private

      USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
                   "(KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Sigsift/0.1".freeze

      def run_with(page, source, opportunity, previous_context)
        session = AgentSession.new(page: page, budget: @budget)
        prompts = Prompts::PlaywrightAgent.new(budget: @budget)
        chat = LLMClient.build(model: @model)

        chat.with_instructions(cached_system_content(prompts.system_prompt))
        chat.with_tools(*prompts.tools(session: session), calls: :many)

        started_at = Time.current
        chat.on_tool_call do |_call|
          session.tool_call_count += 1
          enforce_budget!(session, started_at)
        end
        chat.on_tool_result do |_result|
          # Throttle between turns to stay under Anthropic's tokens-per-minute rate limit.
          # Each turn's input carries the full prior conversation, so input tokens compound.
          sleep(@budget.tool_call_delay_seconds) if @budget.tool_call_delay_seconds.positive?
        end

        begin
          chat.ask(prompts.user_message(source: source, opportunity: opportunity, agent_context: previous_context))
        rescue ScanBudgetExceeded => e
          return scan_failed(session, chat, "budget exceeded (#{e.limit_kind}): #{e.message}")
        rescue => e
          return scan_failed(session, chat, "agent error: #{e.class.name}: #{e.message}")
        end

        accumulate_token_usage(session, chat)
        build_result(session, chat, source, opportunity)
      end

      def enforce_budget!(session, started_at)
        if session.tool_call_count > @budget.max_tool_calls
          raise ScanBudgetExceeded.new(:tool_calls, "exceeded #{@budget.max_tool_calls} tool calls")
        end

        elapsed = Time.current - started_at
        if elapsed > @budget.max_seconds
          raise ScanBudgetExceeded.new(:seconds, "exceeded #{@budget.max_seconds}s wall clock")
        end

        cost = session.total_cost_dollars
        if cost > @budget.max_dollars
          raise ScanBudgetExceeded.new(:dollars, "exceeded $#{@budget.max_dollars} budget (spent $#{cost.round(3)})")
        end
      end

      def accumulate_token_usage(session, chat)
        chat.messages.each do |msg|
          session.total_input_tokens += msg.input_tokens.to_i if msg.respond_to?(:input_tokens)
          session.total_output_tokens += msg.output_tokens.to_i if msg.respond_to?(:output_tokens)
          session.total_cached_tokens += msg.cached_tokens.to_i if msg.respond_to?(:cached_tokens)
        end
      end

      def build_result(session, chat, source, opportunity)
        metrics = build_metrics(session)
        messages = serialize_messages(chat)

        case session.terminator&.fetch(:kind, nil)
        when :findings
          findings = normalize_findings(session.terminator[:findings])
          findings = findings.sort_by { |f| -(f[:confidence_score] || 0).to_f }.first(@budget.max_findings)

          ScanResult::Findings.new(
            findings: findings,
            summary: session.terminator[:summary],
            agent_context: build_agent_context(session, findings),
            metrics: metrics,
            messages: messages
          )
        when :escalated
          ScanResult::Escalated.new(
            reason: session.terminator[:reason],
            agent_context: build_agent_context(session, []),
            metrics: metrics,
            messages: messages
          )
        else
          ScanResult::Failed.new(
            error_message: "agent did not call submit_findings or escalate before ending",
            agent_context: build_agent_context(session, []),
            metrics: metrics,
            messages: messages
          )
        end
      end

      def scan_failed(session, chat, error_message)
        accumulate_token_usage(session, chat)
        ScanResult::Failed.new(
          error_message: error_message,
          agent_context: build_agent_context(session, []),
          metrics: build_metrics(session),
          messages: serialize_messages(chat)
        )
      end

      def build_metrics(session)
        {
          tool_calls_count: session.tool_call_count,
          total_input_tokens: session.total_input_tokens,
          total_output_tokens: session.total_output_tokens,
          total_cost_cents: session.total_cost_cents
        }
      end

      def build_agent_context(session, findings)
        recent = findings.map { |f| { "title" => f[:title], "client_name" => f[:client_name] } }

        {
          recent_findings_titles: recent,
          navigation_breadcrumbs: session.navigation_breadcrumbs,
          last_run_at: Time.current.iso8601
        }.to_json
      end

      def serialize_messages(chat)
        chat.messages.map { |msg| message_to_hash(msg) }
      rescue
        []
      end

      def message_to_hash(msg)
        {
          role: msg.role.to_s,
          content: msg.content.to_s,
          tool_calls: (msg.tool_calls || {}).transform_values(&:to_h),
          tool_call_id: msg.tool_call_id,
          input_tokens: msg.respond_to?(:input_tokens) ? msg.input_tokens : nil,
          output_tokens: msg.respond_to?(:output_tokens) ? msg.output_tokens : nil,
          cached_tokens: msg.respond_to?(:cached_tokens) ? msg.cached_tokens : nil
        }
      rescue
        { role: "unknown", content: msg.inspect }
      end

      def normalize_findings(raw_findings)
        Array(raw_findings).map do |finding|
          h = finding.respond_to?(:to_h) ? finding.to_h : finding
          h.transform_keys(&:to_sym)
        end
      end

      def cached_system_content(text)
        # Mark the system prompt as cacheable so subsequent turns within the 5-minute
        # window only pay ~10% of the input rate for these tokens.
        RubyLLM::Providers::Anthropic::Content.new(text, cache: true)
      rescue NameError
        # Anthropic provider not loaded — fall back to plain string.
        text
      end

      def playwright_cli_path
        # Use the playwright CLI from node_modules (installed via `npm install playwright`)
        # or globally (via `npm install -g playwright`).
        path = ENV["PLAYWRIGHT_CLI_EXECUTABLE_PATH"]
        return path if path

        local = Rails.root.join("node_modules", ".bin", "playwright").to_s
        return local if File.executable?(local)

        # Fallback: rely on `npx playwright` shim resolution
        which = `which playwright 2>/dev/null`.strip
        return which if which.present?

        "npx playwright"
      end
    end
  end
end
