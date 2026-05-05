module Scanning
  class ProcessFindings
    def initialize(scan_run:, findings:, detector: nil)
      @scan_run = scan_run
      @findings = findings
      @detector = detector || DuplicateDetection::Fingerprint.new(source: scan_run.source)
    end

    def call
      @findings.each { |finding| process(finding) }
    end

    private

    def process(finding)
      case @detector.classify(finding)
      when :skip
        # dismissed within cooldown — do nothing
      when :detection_only
        LeadDetection.create!(
          scan_run: @scan_run,
          potential_lead: @detector.existing,
          description: finding[:detection_description].presence || "Found again during scan of #{@scan_run.source.name}."
        )
      when :new
        potential_lead = PotentialLead.create!(
          source: @scan_run.source,
          found_by: @scan_run,
          fingerprint: DuplicateDetection::Fingerprint.compute_fingerprint(finding),
          title: finding[:title],
          description: finding[:description],
          raw_text: finding[:raw_text],
          client_name: finding[:client_name],
          location: finding[:location],
          source_url: finding[:source_url],
          estimated_budget: finding[:estimated_budget],
          deadline_text: finding[:deadline_text],
          deadline_date: finding[:deadline_date],
          contact_info: finding[:contact_info]&.to_json,
          confidence_score: finding[:confidence_score],
          review_status: :pending
        )
        LeadDetection.create!(
          scan_run: @scan_run,
          potential_lead: potential_lead,
          description: finding[:detection_description].presence || "First detected during scan of #{@scan_run.source.name}."
        )
      end
    end
  end
end
