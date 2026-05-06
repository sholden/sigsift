class ScanRunsController < ApplicationController
  before_action :set_scan_run

  def trace
    @trace = @scan_run.trace
  end

  private

  def set_scan_run
    opportunity = current_account.opportunities.find(params[:opportunity_id])
    source = opportunity.sources.find(params[:source_id])
    @scan_run = source.scan_runs.find(params[:id])
  end
end
