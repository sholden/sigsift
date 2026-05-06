module Scanning
  module Tools
    class Escalate < Base
      description "Call this if you cannot complete the scan. Reasons to escalate include: " \
                  "captcha or anti-bot challenges, login walls, JS-required content you cannot interact with, " \
                  "PDF-only sources (not supported in this version), or repeated empty/blank results from navigation. " \
                  "After calling this, end the conversation. Do not call any more tools."

      param :reason, type: :string, desc: "Concise explanation of why the scan cannot continue.", required: true

      def execute(reason:)
        @session.terminator = { kind: :escalated, reason: reason.to_s }
        "Escalated. End the conversation now — do not call any more tools."
      end
    end
  end
end
