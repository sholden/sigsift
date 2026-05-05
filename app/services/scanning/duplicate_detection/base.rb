module Scanning
  module DuplicateDetection
    class Base
      DISMISSED_COOLDOWN = 60.days

      def initialize(source:)
        @source = source
      end

      # Returns :skip, :new, or :detection_only
      #   :skip            — don't create anything (dismissed within cooldown)
      #   :new             — create a new PotentialLead + LeadDetection
      #   :detection_only  — existing lead still active; add LeadDetection only
      def classify(finding)
        raise NotImplementedError, "#{self.class} must implement #classify"
      end

      # Returns the existing PotentialLead if one was found, nil otherwise.
      # Only meaningful after calling #classify returned :detection_only.
      def existing
        raise NotImplementedError, "#{self.class} must implement #existing"
      end
    end
  end
end
