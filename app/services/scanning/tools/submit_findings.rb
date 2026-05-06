module Scanning
  module Tools
    class SubmitFindings < Base
      description "Call this exactly ONCE when you have completed your scan. " \
                  "If you found no relevant new opportunities, pass an empty findings array — that's a valid outcome. " \
                  "After calling this, end the conversation. Do not call any more tools."

      param :findings, type: :array, desc: <<~DESC, required: true
        Array of finding objects. Each must include:
          - title (string, required)
          - confidence_score (number 0-1, required)
        And may include: description, client_name, location, source_url, estimated_budget,
        deadline_text, deadline_date (ISO 8601), contact_info (object with name/email/phone),
        detection_description (string explaining where/how this was found).
      DESC
      param :summary, type: :string, desc: "Human-readable one-sentence summary of what happened in the scan.", required: true
      param :navigation_breadcrumbs, type: :array, desc: "Optional: list of strings describing your navigation path.", required: false

      def execute(findings:, summary:, navigation_breadcrumbs: [])
        @session.terminator = {
          kind: :findings,
          findings: Array(findings),
          summary: summary.to_s,
          breadcrumbs: Array(navigation_breadcrumbs)
        }
        "Findings submitted (#{findings.length} items). End the conversation now — do not call any more tools."
      end
    end
  end
end
