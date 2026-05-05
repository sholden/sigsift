class Source < ApplicationRecord
  belongs_to :opportunity
  has_many :scan_runs, dependent: :destroy
  has_many :potential_leads, dependent: :destroy

  enum :status, { active: "active", paused: "paused" }

  validates :name, presence: true
  validates :status, presence: true
  validates :scan_frequency_days, numericality: { greater_than: 0 }

  scope :active_ordered, -> { active.order(:name) }
  scope :due_for_scan, -> {
    active.where(last_scanned_at: nil)
          .or(active.where("last_scanned_at < ?", Time.current - minimum_scan_frequency))
  }

  def due_for_scan?
    last_scanned_at.nil? || last_scanned_at < scan_frequency_days.days.ago
  end

  def next_scan_at
    return Time.current if last_scanned_at.nil?
    last_scanned_at + scan_frequency_days.days
  end

  private

  def self.minimum_scan_frequency
    minimum(:scan_frequency_days).days
  end
end
