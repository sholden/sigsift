class AddFingerprintToPotentialLeads < ActiveRecord::Migration[8.1]
  def change
    add_column :potential_leads, :fingerprint, :string
    add_index :potential_leads, [ :source_id, :fingerprint ]
  end
end
