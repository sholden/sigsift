module Scanning
  module Tools
    class Fill < Base
      description "Fill a text input, textarea, or contenteditable element with a value. " \
                  "Replaces any existing content."

      param :selector, type: :string, desc: "CSS selector for the input element", required: true
      param :value, type: :string, desc: "Text to fill in", required: true

      def execute(selector:, value:)
        @session.page.fill(selector, value, timeout: 10_000)
        "filled #{selector} with #{value.length} chars"
      rescue => e
        "fill failed: #{e.message}"
      end
    end
  end
end
