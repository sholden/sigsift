module Scanning
  class AgentSession
    attr_reader :page, :budget
    attr_accessor :tool_call_count, :total_input_tokens, :total_output_tokens, :total_cached_tokens, :navigation_breadcrumbs
    attr_accessor :terminator

    def initialize(page:, budget:)
      @page = page
      @budget = budget
      @tool_call_count = 0
      @total_input_tokens = 0
      @total_output_tokens = 0
      @total_cached_tokens = 0
      @navigation_breadcrumbs = []
      @terminator = nil
    end

    # Set when SubmitFindings or Escalate is called.
    # Shape: { kind: :findings, findings:, summary:, breadcrumbs: } or { kind: :escalated, reason: }
    def terminated?
      !@terminator.nil?
    end

    def total_cost_dollars
      input_rate, output_rate, cached_rate = pricing_for(Rails.application.config.x.scanning.agent_model)
      ((@total_input_tokens - @total_cached_tokens) * input_rate +
       @total_cached_tokens * cached_rate +
       @total_output_tokens * output_rate) / 1_000_000.0
    end

    def total_cost_cents
      (total_cost_dollars * 100).round
    end

    private

    # Per-million-token rates (USD). Hardcoded for known models — extend as needed.
    def pricing_for(model)
      case model
      when /haiku-4-5/
        [1.0, 5.0, 0.10]   # input, output, cached-input
      when /sonnet-4/
        [3.0, 15.0, 0.30]
      when /opus-4/
        [15.0, 75.0, 1.50]
      else
        [1.0, 5.0, 0.10]   # default to Haiku-ish
      end
    end
  end
end
