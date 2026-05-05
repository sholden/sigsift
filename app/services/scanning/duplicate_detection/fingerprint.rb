module Scanning
  module DuplicateDetection
    class Fingerprint < Base
      def initialize(source:)
        super
        @existing_lead = nil
      end

      def classify(finding)
        @existing_lead = find_existing(finding)
        return :new if @existing_lead.nil?

        if @existing_lead.pending? || @existing_lead.created_lead?
          :detection_only
        elsif @existing_lead.dismissed?
          @existing_lead.reviewed_at < DISMISSED_COOLDOWN.ago ? :new : :skip
        else
          :new
        end
      end

      def existing
        @existing_lead
      end

      def self.compute_fingerprint(finding)
        components = [
          finding[:title].to_s.downcase.gsub(/\s+/, " ").strip,
          finding[:client_name].to_s.downcase.strip
        ]
        Digest::MD5.hexdigest(components.join("|"))
      end

      private

      def find_existing(finding)
        scope = PotentialLead.where(source: @source)

        if finding[:source_url].present?
          scope.find_by(source_url: finding[:source_url])
        else
          scope.find_by(fingerprint: self.class.compute_fingerprint(finding))
        end
      end
    end
  end
end
