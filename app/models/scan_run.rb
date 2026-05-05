class ScanRun < ApplicationRecord
  belongs_to :source
  has_many :potential_leads, foreign_key: :found_by_id
  has_many :lead_detections

  enum :status, {
    pending: "pending",
    running: "running",
    completed: "completed",
    failed: "failed",
    no_op: "no_op"
  }

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def opportunity
    source.opportunity
  end

  def duration_seconds
    return nil unless started_at && completed_at
    (completed_at - started_at).round
  end
end
