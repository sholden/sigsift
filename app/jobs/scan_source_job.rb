class ScanSourceJob < ApplicationJob
  queue_as :scanning

  AUTO_PAUSE_THRESHOLD = 3

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3

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

    persist_metrics(scan_run, result.metrics)
    persist_trace(scan_run, result.messages, result.metrics)

    case result
    when Scanning::ScanResult::Findings
      Scanning::ProcessFindings.new(scan_run: scan_run, findings: result.findings).call
      final_status = result.findings.any? ? :completed : :no_op
      scan_run.update!(
        status: final_status,
        summary: result.summary,
        agent_context: result.agent_context,
        completed_at: Time.current
      )
      reset_failure_count(source)
    when Scanning::ScanResult::Escalated
      scan_run.update!(
        status: :failed,
        error_message: "escalated: #{result.reason}",
        agent_context: result.agent_context,
        completed_at: Time.current
      )
      bump_failure_count(source)
    when Scanning::ScanResult::Failed
      scan_run.update!(
        status: :failed,
        error_message: result.error_message,
        agent_context: result.agent_context,
        completed_at: Time.current
      )
      bump_failure_count(source)
    end

    source.update!(last_scanned_at: Time.current)
    broadcast_status(source, scan_run)
  rescue => e
    scan_run&.update!(status: :failed, error_message: e.message, completed_at: Time.current)
    bump_failure_count(source) if source
    broadcast_status(source, scan_run) if source
    raise
  end

  private

  def persist_metrics(scan_run, metrics)
    return if metrics.blank?
    scan_run.update_columns(
      tool_calls_count: metrics[:tool_calls_count].to_i,
      total_input_tokens: metrics[:total_input_tokens].to_i,
      total_output_tokens: metrics[:total_output_tokens].to_i,
      total_cost_cents: metrics[:total_cost_cents].to_i
    )
  end

  def persist_trace(scan_run, messages, metrics)
    return if messages.blank? && metrics.blank?
    ScanRunTrace.create!(
      scan_run: scan_run,
      messages_json: messages.to_json,
      metadata_json: metrics.to_json
    )
  rescue => e
    Rails.logger.error "Failed to persist trace for ScanRun #{scan_run.id}: #{e.message}"
  end

  def bump_failure_count(source)
    new_count = source.consecutive_failure_count + 1
    if new_count >= AUTO_PAUSE_THRESHOLD
      source.update!(consecutive_failure_count: new_count, status: :paused)
    else
      source.update!(consecutive_failure_count: new_count)
    end
  end

  def reset_failure_count(source)
    return if source.consecutive_failure_count.zero?
    source.update!(consecutive_failure_count: 0)
  end

  def broadcast_status(source, scan_run)
    Turbo::StreamsChannel.broadcast_replace_to(
      "source_#{source.id}",
      target: "scan_status",
      partial: "sources/scan_status",
      locals: { source: source, scan_run: scan_run }
    )
  end
end
