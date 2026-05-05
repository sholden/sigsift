class CreateLeadDetections < ActiveRecord::Migration[8.1]
  def change
    create_table :lead_detections do |t|
      t.references :scan_run, null: false, foreign_key: true
      t.references :potential_lead, null: false, foreign_key: true
      t.text :description

      t.datetime :created_at, null: false
    end
  end
end
