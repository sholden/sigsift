module Scanning
  module Tools
    class SelectOption < Base
      description "Select an option in a <select> dropdown by value or label."

      param :selector, type: :string, desc: "CSS selector for the <select> element", required: true
      param :value, type: :string, desc: "Option value (or label) to choose", required: true

      def execute(selector:, value:)
        @session.page.select_option(selector, value: value)
        "selected #{value} on #{selector}"
      rescue => e
        # Try by label if value match failed
        begin
          @session.page.select_option(selector, label: value)
          "selected #{value} (by label) on #{selector}"
        rescue => e2
          "select_option failed: #{e2.message}"
        end
      end
    end
  end
end
