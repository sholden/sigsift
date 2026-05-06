module Scanning
  module Tools
    class Base < RubyLLM::Tool
      def initialize(session:)
        super()
        @session = session
      end
    end
  end
end
