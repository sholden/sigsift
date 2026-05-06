module Scanning
  class AgentRunner
    def initialize(source:, opportunity:, previous_context: nil, strategy: nil)
      @source = source
      @opportunity = opportunity
      @previous_context = previous_context
      @strategy = strategy || default_strategy.new
    end

    def call
      @strategy.call(
        source: @source,
        opportunity: @opportunity,
        previous_context: @previous_context
      )
    end

    private

    def default_strategy
      Rails.application.config.x.scanning.strategy_name.constantize
    end
  end
end
