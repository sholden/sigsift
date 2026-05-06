module Scanning
  module Tools
    class Scroll < Base
      description "Scroll the page. Useful for triggering lazy-loaded content. " \
                  "Direction is 'down' or 'up'; amount is in pixels (default 800)."

      param :direction, type: :string, desc: "'down' or 'up'", required: true
      param :amount, type: :integer, desc: "Pixels to scroll (default 800)", required: false

      def execute(direction:, amount: 800)
        amount = (amount || 800).to_i
        delta = direction == "up" ? -amount : amount
        @session.page.evaluate("window.scrollBy(0, #{delta})")
        "scrolled #{direction} by #{amount}px"
      rescue => e
        "scroll failed: #{e.message}"
      end
    end
  end
end
