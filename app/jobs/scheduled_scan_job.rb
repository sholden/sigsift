class ScheduledScanJob < ApplicationJob
  queue_as :default

  def perform
    Source.active.find_each do |source|
      ScanSourceJob.perform_later(source.id) if source.due_for_scan?
    end
  end
end
