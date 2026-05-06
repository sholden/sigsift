module Scanning
  module Tools
    class WaitForLoadState < Base
      description "Wait for the page to reach a load state. Use 'networkidle' for JS-heavy pages " \
                  "where content loads after the initial DOM ready event."

      param :state, type: :string, desc: "One of: load, domcontentloaded, networkidle", required: true

      def execute(state:)
        unless %w[load domcontentloaded networkidle].include?(state)
          return "invalid state: #{state}. must be one of load, domcontentloaded, networkidle"
        end

        @session.page.wait_for_load_state(state: state, timeout: 15_000)
        "reached #{state}"
      rescue => e
        "wait failed: #{e.message}"
      end
    end
  end
end
