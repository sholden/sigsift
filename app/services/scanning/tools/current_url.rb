module Scanning
  module Tools
    class CurrentUrl < Base
      description "Return the URL of the currently displayed page."

      def execute
        @session.page.url
      end
    end
  end
end
