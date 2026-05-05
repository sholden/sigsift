class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.references :opportunity, null: false, foreign_key: true
      t.references :potential_lead, null: true, foreign_key: true
      t.string :title
      t.text :description
      t.text :notes
      t.string :status
      t.boolean :active, null: false, default: true
      t.string :client_name
      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone
      t.integer :estimated_budget_cents
      t.date :deadline
      t.string :time_horizon
      t.string :priority

      t.timestamps
    end
  end
end
