module Scanning
  module Tools
    class Back < Base
      description "Navigate back to the previous page in browser history."

      def execute
        @session.page.go_back(timeout: 15_000)
        @session.navigation_breadcrumbs << "back"
        "navigated back to #{@session.page.url}"
      rescue => e
        "back failed: #{e.message}"
      end
    end
  end
end
