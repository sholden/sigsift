class AddConsecutiveFailureCountToSources < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :consecutive_failure_count, :integer, default: 0, null: false
  end
end
