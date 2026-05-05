class LeadsController < ApplicationController
  before_action :set_lead, only: %i[show edit update destroy]

  def index
    @leads = Lead.joins(:opportunity)
                 .where(opportunities: { account: current_account })
                 .active
                 .ordered
    @leads_by_status = @leads.group_by(&:status)
  end

  def show; end

  def new
    @lead = Lead.new
    @opportunities = current_account.opportunities.active.ordered
  end

  def create
    @lead = Lead.new(lead_params)
    if @lead.save
      redirect_to @lead, notice: "Lead created."
    else
      @opportunities = current_account.opportunities.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @opportunities = current_account.opportunities.active.ordered
  end

  def update
    if @lead.update(lead_params)
      redirect_to @lead, notice: "Lead updated."
    else
      @opportunities = current_account.opportunities.active.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lead.update!(active: false)
    redirect_to leads_path, notice: "Lead archived."
  end

  private

  def set_lead
    @lead = Lead.joins(:opportunity)
                .where(opportunities: { account: current_account })
                .find(params[:id])
  end

  def lead_params
    params.expect(lead: [
      :opportunity_id, :title, :description, :notes, :status, :priority,
      :client_name, :contact_name, :contact_email, :contact_phone,
      :estimated_budget_cents, :deadline, :time_horizon
    ])
  end
end
