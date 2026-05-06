module Scanning
  module ScanResult
    Findings = Data.define(:findings, :summary, :agent_context, :metrics, :messages)
    Escalated = Data.define(:reason, :agent_context, :metrics, :messages)
    Failed = Data.define(:error_message, :agent_context, :metrics, :messages)
  end
end
