module Scanning
  module Strategies
    class Base
      # Strategies return a Scanning::ScanResult variant:
      #   ScanResult::Findings(findings:, summary:, agent_context:, metrics:)
      #   ScanResult::Escalated(reason:, agent_context:, metrics:)
      #   ScanResult::Failed(error_message:, agent_context:, metrics:)
      #
      # findings: Array of hashes with keys:
      #   title:                 String (required)
      #   description:           String
      #   client_name:           String
      #   location:              String
      #   source_url:            String
      #   estimated_budget:      String (raw, e.g. "$2M–$5M")
      #   deadline_text:         String (raw, e.g. "Submissions due March 15")
      #   deadline_date:         Date or nil
      #   contact_info:          Hash (name, email, phone)
      #   confidence_score:      Float 0.0–1.0
      #   detection_description: String (how/where it was found)
      #
      # metrics: Hash with tool_calls_count, total_input_tokens, total_output_tokens, total_cost_cents
      # messages: Array (the full ruby-llm chat.messages history) for trace persistence

      def call(source:, opportunity:, previous_context: nil)
        raise NotImplementedError, "#{self.class} must implement #call"
      end
    end
  end
end
