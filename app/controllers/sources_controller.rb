class SourcesController < ApplicationController
  before_action :set_opportunity
  before_action :set_source, only: %i[show edit update destroy]

  def show
    @scan_runs = @source.scan_runs.recent
    @potential_leads = @source.potential_leads.order(created_at: :desc).limit(10)
  end

  def new
    @source = @opportunity.sources.new
  end

  def create
    @source = @opportunity.sources.new(source_params)
    if @source.save
      redirect_to opportunity_source_path(@opportunity, @source), notice: "Source added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @source.update(source_params)
      redirect_to opportunity_source_path(@opportunity, @source), notice: "Source updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to @opportunity, notice: "Source removed."
  end

  private

  def set_opportunity
    @opportunity = current_account.opportunities.find(params[:opportunity_id])
  end

  def set_source
    @source = @opportunity.sources.find(params[:id])
  end

  def source_params
    params.expect(source: [ :name, :url, :description, :notes, :status, :scan_frequency_days ])
  end
end
