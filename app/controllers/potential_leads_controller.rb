class PotentialLeadsController < ApplicationController
  def index
    @potential_leads = PotentialLead.joins(source: :opportunity)
                                    .where(opportunities: { account: current_account })
                                    .pending_review
                                    .includes(:source, found_by: {})
  end

  def update
    @potential_lead = PotentialLead.joins(source: :opportunity)
                                   .where(opportunities: { account: current_account })
                                   .find(params[:id])

    case params[:review_action]
    when "create_lead"
      result = PotentialLeads::Review.new(potential_lead: @potential_lead).create_lead(lead_params)
      if result.success
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.remove(@potential_lead) }
          format.html { redirect_to potential_leads_path, notice: "Lead created." }
        end
      else
        redirect_to potential_leads_path, alert: result.errors.join(", ")
      end
    when "dismiss"
      @potential_lead.update!(review_status: :dismissed, reviewed_at: Time.current)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@potential_lead) }
        format.html { redirect_to potential_leads_path, notice: "Dismissed." }
      end
    else
      redirect_to potential_leads_path, alert: "Unknown action."
    end
  end

  private

  def lead_params
    params.permit(:title, :opportunity_id, :client_name, :deadline, :estimated_budget_cents, :priority)
  end
end
