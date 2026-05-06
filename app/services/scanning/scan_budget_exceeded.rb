module Scanning
  class ScanBudgetExceeded < StandardError
    attr_reader :limit_kind

    def initialize(limit_kind, message)
      @limit_kind = limit_kind
      super(message)
    end
  end
end
