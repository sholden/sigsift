module Scanning
  module Tools
    class GetHtml < Base
      description "Return the raw HTML of the current page (or a CSS selector). " \
                  "Use sparingly — text-only inspection via get_text is usually cheaper."

      param :selector, type: :string, desc: "CSS selector to scope to (default: full body)", required: false
      param :max_chars, type: :integer, desc: "Truncation limit (default 5000)", required: false

      def execute(selector: nil, max_chars: 5000)
        scope = selector.presence || "body"
        limit = (max_chars || 5000).to_i.clamp(500, 15_000)

        html = @session.page.evaluate(<<~JS, arg: { selector: scope })
          ({ selector }) => {
            const el = document.querySelector(selector);
            return el ? el.outerHTML : null;
          }
        JS

        return "selector matched no elements: #{scope}" if html.nil?

        if html.length > limit
          "#{html[0, limit]}\n\n[truncated; #{html.length - limit} more chars]"
        else
          html
        end
      rescue => e
        "get_html failed: #{e.message}"
      end
    end
  end
end
