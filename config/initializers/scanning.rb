Rails.application.config.x.scanning.tap do |c|
  # Strategy resolution happens at call time via .constantize — initializers
  # run before Zeitwerk autoloads app/services/.
  c.strategy_name = "Scanning::Strategies::PlaywrightAgent"

  # Agent model. Single config knob to swap LLMs (default: cheapest current Anthropic model).
  c.agent_model = "claude-haiku-4-5-20251001"

  # Per-scan budget. tool_call_cap roughly scales as 5 + (max_findings * 5),
  # so if you raise max_findings to 10, also bump tool_call_cap to ~55.
  #
  # tool_call_delay_seconds throttles between tool calls to stay under Anthropic's
  # tokens-per-minute rate limit (Haiku free tier = 50K/min). Each turn's input
  # carries the full conversation history, so input tokens compound across turns.
  c.budget = {
    max_dollars: 0.50,
    max_seconds: 600,
    max_tool_calls: 100,
    max_findings: 3,
    tool_call_delay_seconds: 2
  }
end
