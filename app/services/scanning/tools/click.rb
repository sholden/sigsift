module Scanning
  module Tools
    class Click < Base
      description "Click an element matching a CSS selector. Auto-waits for the element to be actionable."

      param :selector, type: :string, desc: "CSS selector for the element to click", required: true

      def execute(selector:)
        @session.page.click(selector, timeout: 10_000)
        @session.navigation_breadcrumbs << "click #{selector}"
        "clicked #{selector}"
      rescue => e
        "click failed: #{e.message}"
      end
    end
  end
end
