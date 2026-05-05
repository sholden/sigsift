module PotentialLeads
  class Review
    Result = Data.define(:success, :lead, :errors)

    def initialize(potential_lead:)
      @potential_lead = potential_lead
    end

    def create_lead(overrides = {})
      ActiveRecord::Base.transaction do
        lead = Lead.create!(lead_attributes.merge(overrides.to_h.compact))
        @potential_lead.update!(review_status: :created_lead, reviewed_at: Time.current)
        Result.new(success: true, lead: lead, errors: [])
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, lead: nil, errors: e.record.errors.full_messages)
    end

    private

    def lead_attributes
      {
        opportunity: @potential_lead.opportunity,
        potential_lead: @potential_lead,
        title: @potential_lead.title,
        description: @potential_lead.description,
        client_name: @potential_lead.client_name,
        deadline: @potential_lead.deadline_date,
        status: :new_lead
      }
    end
  end
end
