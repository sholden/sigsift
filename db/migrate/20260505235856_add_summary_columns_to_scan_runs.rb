class AddSummaryColumnsToScanRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :scan_runs, :tool_calls_count, :integer, default: 0, null: false
    add_column :scan_runs, :total_input_tokens, :integer, default: 0, null: false
    add_column :scan_runs, :total_output_tokens, :integer, default: 0, null: false
    add_column :scan_runs, :total_cost_cents, :integer, default: 0, null: false
  end
end
