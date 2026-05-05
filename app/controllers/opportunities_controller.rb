class OpportunitiesController < ApplicationController
  before_action :set_opportunity, only: %i[show edit update destroy]

  def index
    @opportunities = current_account.opportunities.ordered
  end

  def show
    @sources = @opportunity.sources.order(:name)
    @leads = @opportunity.leads.active.ordered
    @recent_scan_runs = ScanRun.joins(:source)
                               .where(sources: { opportunity: @opportunity })
                               .recent
                               .limit(5)
  end

  def new
    @opportunity = current_account.opportunities.new
  end

  def create
    @opportunity = current_account.opportunities.new(opportunity_params)
    if @opportunity.save
      redirect_to @opportunity, notice: "Opportunity created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @opportunity.update(opportunity_params)
      redirect_to @opportunity, notice: "Opportunity updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @opportunity.destroy
    redirect_to opportunities_path, notice: "Opportunity deleted."
  end

  private

  def set_opportunity
    @opportunity = current_account.opportunities.find(params[:id])
  end

  def opportunity_params
    params.expect(opportunity: [ :name, :description, :criteria_text, :status ])
  end
end
