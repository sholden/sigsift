class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.references :opportunity, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url
      t.text :description
      t.text :notes
      t.string :status, null: false, default: "active"
      t.datetime :last_scanned_at
      t.integer :scan_frequency_days, null: false, default: 7

      t.timestamps
    end

    add_index :sources, :status
    add_index :sources, :last_scanned_at
  end
end
