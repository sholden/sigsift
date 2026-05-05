module Scanning
  class AgentRunner
    def initialize(source:, opportunity:, previous_context: nil, adapter: nil)
      @source = source
      @opportunity = opportunity
      @previous_context = previous_context
      @adapter = adapter || default_adapter.new
    end

    def call
      @adapter.call(
        source: @source,
        opportunity: @opportunity,
        previous_context: @previous_context
      )
    end

    private

    def default_adapter
      Rails.application.config.x.scanning.adapter_name.constantize
    end
  end
end
