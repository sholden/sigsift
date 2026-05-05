class CreateScanRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :scan_runs do |t|
      t.references :source, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.text :summary
      t.text :agent_context
      t.datetime :started_at
      t.datetime :completed_at
      t.text :error_message
      t.string :job_id

      t.timestamps
    end

    add_index :scan_runs, :status
    add_index :scan_runs, [ :source_id, :created_at ]
  end
end
