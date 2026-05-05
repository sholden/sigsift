class CreateOpportunities < ActiveRecord::Migration[8.1]
  def change
    create_table :opportunities do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.text :criteria_text
      t.text :criteria_structured
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :opportunities, :status
  end
end
