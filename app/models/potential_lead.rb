class PotentialLead < ApplicationRecord
  belongs_to :source
  belongs_to :found_by, class_name: "ScanRun"
  has_many :lead_detections, dependent: :destroy
  has_one :lead, dependent: :nullify

  enum :review_status, {
    pending: "pending",
    created_lead: "created_lead",
    dismissed: "dismissed"
  }

  validates :title, presence: true
  validates :review_status, presence: true

  scope :pending_review, -> { pending.order(created_at: :desc) }
  scope :recently_dismissed, -> { dismissed.where("reviewed_at > ?", 60.days.ago) }

  def opportunity
    source.opportunity
  end
end
