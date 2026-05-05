module Scanning
  module Adapters
    class Base
      Result = Data.define(:findings, :agent_context, :summary)

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
      # agent_context: String (JSON for next run's memory)
      # summary:       String (human-readable description of what happened)

      def call(source:, opportunity:, previous_context: nil)
        raise NotImplementedError, "#{self.class} must implement #call"
      end
    end
  end
end
