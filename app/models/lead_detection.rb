class LeadDetection < ApplicationRecord
  belongs_to :scan_run
  belongs_to :potential_lead

  validates :description, presence: true

  # Immutable — no updated_at
  def readonly?
    !new_record?
  end
end
