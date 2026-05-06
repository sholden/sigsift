class CreateScanRunTraces < ActiveRecord::Migration[8.1]
  def change
    create_table :scan_run_traces do |t|
      t.references :scan_run, null: false, foreign_key: true, index: { unique: true }
      t.text :messages_json
      t.text :metadata_json

      t.timestamps
    end
  end
end
