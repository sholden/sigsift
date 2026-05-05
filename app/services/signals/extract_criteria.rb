module Signals
  class ExtractCriteria
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are a structured data extractor. Given a plain-language description of what type of business opportunities someone is looking for, extract the key search criteria as JSON.

      Return only valid JSON with these fields (omit any that aren't mentioned):
      {
        "keywords": ["array", "of", "search", "terms"],
        "location": "city, state or region",
        "min_budget_usd": 0,
        "max_budget_usd": 0,
        "project_types": ["array", "of", "project", "types"],
        "client_types": ["government", "private", "nonprofit", etc.],
        "exclusions": ["things", "to", "exclude"]
      }
    PROMPT

    def initialize(opportunity:)
      @opportunity = opportunity
    end

    def call
      return if @opportunity.criteria_text.blank?

      client = Anthropic::Client.new
      response = client.messages(
        model: "claude-haiku-4-5-20251001",
        max_tokens: 512,
        system: SYSTEM_PROMPT,
        messages: [ { role: "user", content: @opportunity.criteria_text } ]
      )

      json_text = response.dig("content", 0, "text")
      JSON.parse(json_text)
      @opportunity.update_column(:criteria_structured, json_text)
    rescue JSON::ParserError, Anthropic::Error => e
      Rails.logger.error "ExtractCriteria failed for opportunity #{@opportunity.id}: #{e.message}"
    end
  end
end
