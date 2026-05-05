class CreatePotentialLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :potential_leads do |t|
      t.references :source, null: false, foreign_key: true
      t.references :found_by, null: false, foreign_key: { to_table: :scan_runs }
      t.string :title
      t.text :description
      t.text :raw_text
      t.string :client_name
      t.string :location
      t.string :source_url
      t.string :estimated_budget
      t.string :deadline_text
      t.date :deadline_date
      t.text :contact_info
      t.float :confidence_score
      t.string :review_status
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :potential_leads, :review_status
    add_index :potential_leads, [ :source_id, :review_status ]
  end
end
