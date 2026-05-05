module Scanning
  module Adapters
    class Stub < Base
      def call(source:, opportunity:, previous_context: nil)
        findings = generate_findings(source, opportunity)
        summary = findings.any? ? "Found #{findings.count} potential #{"lead".pluralize(findings.count)}." : "No new findings."

        Result.new(
          findings: findings,
          agent_context: { scanned_at: Time.current.iso8601, items_seen: findings.count }.to_json,
          summary: summary
        )
      end

      private

      def generate_findings(source, opportunity)
        # Return 0 findings sometimes to exercise the no_op path
        return [] if rand < 0.2

        count = rand(1..3)
        count.times.map { |i| build_finding(source, opportunity, i) }
      end

      def build_finding(source, opportunity, index)
        titles = [
          "#{Faker::Company.name} Facility Roof Replacement",
          "#{Faker::Address.city} Public Works — Roofing Project",
          "#{Faker::Company.name} Building Renovation — Phase #{index + 1}",
          "#{Faker::Address.city} School District Capital Project"
        ]

        {
          title: titles.sample,
          description: "This is a stub finding generated for testing. Source: #{source.name}. Opportunity: #{opportunity.name}.",
          client_name: Faker::Company.name,
          location: "#{Faker::Address.city}, #{Faker::Address.state_abbr}",
          source_url: source.url.present? ? "#{source.url}#item-#{SecureRandom.hex(4)}" : nil,
          estimated_budget: ["$250k–$500k", "$500k–$1M", "$1M–$2.5M", "~$750k"].sample,
          deadline_text: "Proposals due #{Faker::Date.forward(days: 60).strftime("%B %-d, %Y")}",
          deadline_date: Faker::Date.forward(days: 60),
          contact_info: { name: Faker::Name.name, email: Faker::Internet.email, phone: Faker::PhoneNumber.phone_number },
          confidence_score: rand(0.6..0.98).round(2),
          detection_description: "Found in stub scan of #{source.name} for #{opportunity.name}."
        }
      end
    end
  end
end
