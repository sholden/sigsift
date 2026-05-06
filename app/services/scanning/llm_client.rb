module Scanning
  class LLMClient
    def self.build(model: nil)
      RubyLLM.chat(model: model || Rails.application.config.x.scanning.agent_model)
    end
  end
end
