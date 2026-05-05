class ScanSourceJob < ApplicationJob
  queue_as :scanning

  def perform(source_id)
    source = Source.find(source_id)
    scan_run = source.scan_runs.create!(status: :running, started_at: Time.current)

    broadcast_status(source, scan_run)

    previous_context = source.scan_runs
                             .where(status: :completed)
                             .order(created_at: :desc)
                             .pick(:agent_context)

    result = Scanning::AgentRunner.new(
      source: source,
      opportunity: source.opportunity,
      previous_context: previous_context
    ).call

    Scanning::ProcessFindings.new(scan_run: scan_run, findings: result.findings).call

    final_status = result.findings.any? ? :completed : :no_op
    scan_run.update!(
      status: final_status,
      summary: result.summary,
      agent_context: result.agent_context,
      completed_at: Time.current
    )
    source.update!(last_scanned_at: Time.current)

    broadcast_status(source, scan_run)
  rescue => e
    scan_run&.update!(status: :failed, error_message: e.message, completed_at: Time.current)
    broadcast_status(source, scan_run) if source
    raise
  end

  private

  def broadcast_status(source, scan_run)
    Turbo::StreamsChannel.broadcast_replace_to(
      "source_#{source.id}",
      target: "scan_status",
      partial: "sources/scan_status",
      locals: { source: source, scan_run: scan_run }
    )
  end
end
