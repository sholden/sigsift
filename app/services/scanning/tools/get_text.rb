module Scanning
  module Tools
    class GetText < Base
      description "Extract the visible text content of the current page (or a CSS selector). " \
                  "Strips nav, footer, script, and style elements. Truncated to ~10,000 chars."

      param :selector, type: :string, desc: "Optional CSS selector (e.g. 'main', '.results'). Omit for full page.", required: false

      MAX_CHARS = 6_000
      STRIP_TAGS = "script, style, nav, footer, header, noscript, iframe".freeze

      def execute(selector: nil)
        scope = selector.presence || "body"
        text = @session.page.evaluate(<<~JS, arg: { selector: scope, strip: STRIP_TAGS })
          ({ selector, strip }) => {
            const root = document.querySelector(selector);
            if (!root) return null;
            const clone = root.cloneNode(true);
            clone.querySelectorAll(strip).forEach(el => el.remove());
            return clone.innerText.replace(/\\n{3,}/g, "\\n\\n").trim();
          }
        JS

        return "selector matched no elements: #{scope}" if text.nil?
        return "page is empty" if text.empty?

        if text.length > MAX_CHARS
          "#{text[0, MAX_CHARS]}\n\n[truncated; #{text.length - MAX_CHARS} more chars]"
        else
          text
        end
      rescue => e
        "get_text failed: #{e.message}"
      end
    end
  end
end
