class Lead < ApplicationRecord
  belongs_to :opportunity
  belongs_to :potential_lead, optional: true

  enum :status, {
    new_lead: "new",
    tracking: "tracking",
    proposal_sent: "proposal_sent",
    won: "won",
    lost: "lost"
  }

  enum :priority, { low: "low", medium: "medium", high: "high", urgent: "urgent" }

  validates :title, presence: true
  validates :status, presence: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_deadline, -> { order(Arel.sql("deadline IS NULL, deadline ASC")) }
  scope :ordered, -> { order(created_at: :desc) }

  def budget_display
    return nil unless estimated_budget_cents
    "$#{format("%.0f", estimated_budget_cents / 100.0)}"
  end

  def source
    potential_lead&.source
  end
end
