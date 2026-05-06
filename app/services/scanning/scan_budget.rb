module Scanning
  class ScanBudget
    attr_reader :max_dollars, :max_seconds, :max_tool_calls, :max_findings, :tool_call_delay_seconds

    def self.default
      cfg = Rails.application.config.x.scanning.budget
      new(
        max_dollars: cfg[:max_dollars],
        max_seconds: cfg[:max_seconds],
        max_tool_calls: cfg[:max_tool_calls],
        max_findings: cfg[:max_findings],
        tool_call_delay_seconds: cfg[:tool_call_delay_seconds] || 0
      )
    end

    def initialize(max_dollars:, max_seconds:, max_tool_calls:, max_findings:, tool_call_delay_seconds: 0)
      @max_dollars = max_dollars
      @max_seconds = max_seconds
      @max_tool_calls = max_tool_calls
      @max_findings = max_findings
      @tool_call_delay_seconds = tool_call_delay_seconds
    end

    def merge(overrides)
      self.class.new(
        max_dollars: overrides[:max_dollars] || max_dollars,
        max_seconds: overrides[:max_seconds] || max_seconds,
        max_tool_calls: overrides[:max_tool_calls] || max_tool_calls,
        max_findings: overrides[:max_findings] || max_findings,
        tool_call_delay_seconds: overrides[:tool_call_delay_seconds] || tool_call_delay_seconds
      )
    end
  end
end
