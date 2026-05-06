module Scanning
  module Tools
    class GetLinks < Base
      description "List anchor links on the current page (or within a CSS selector). " \
                  "Returns text + href for each. Optionally filter by substring match against the link text."

      param :selector, type: :string, desc: "CSS scope to search within (default: full page)", required: false
      param :filter, type: :string, desc: "Case-insensitive substring filter on link text", required: false
      param :limit, type: :integer, desc: "Maximum number of links to return (default 50)", required: false

      def execute(selector: nil, filter: nil, limit: 50)
        scope = selector.presence || "body"
        limit = (limit || 50).to_i.clamp(1, 200)

        links = @session.page.evaluate(<<~JS, arg: { selector: scope })
          ({ selector }) => {
            const root = document.querySelector(selector);
            if (!root) return null;
            return Array.from(root.querySelectorAll("a[href]")).map(a => ({
              text: (a.innerText || a.textContent || "").trim().slice(0, 300),
              href: a.href
            })).filter(l => l.text.length > 0 || l.href);
          }
        JS

        return "selector matched no elements: #{scope}" if links.nil?
        return "no links found" if links.empty?

        if filter.present?
          needle = filter.downcase
          links = links.select { |l| l["text"].to_s.downcase.include?(needle) }
        end

        links.first(limit).map { |l| "#{l["text"]} → #{l["href"]}" }.join("\n")
      rescue => e
        "get_links failed: #{e.message}"
      end
    end
  end
end
