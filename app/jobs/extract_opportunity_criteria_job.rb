class ExtractOpportunityCriteriaJob < ApplicationJob
  queue_as :default

  def perform(opportunity_id)
    opportunity = Opportunity.find(opportunity_id)
    return if opportunity.criteria_text.blank?

    Signals::ExtractCriteria.new(opportunity: opportunity).call

    Turbo::StreamsChannel.broadcast_replace_to(
      "opportunity_#{opportunity.id}",
      target: "criteria_structured",
      partial: "opportunities/criteria_structured",
      locals: { opportunity: opportunity.reload }
    )
  end
end
