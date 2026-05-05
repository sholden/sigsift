class Opportunity < ApplicationRecord
  belongs_to :account
  has_many :sources, dependent: :destroy
  has_many :leads, dependent: :destroy

  enum :status, { active: "active", paused: "paused", archived: "archived" }

  validates :name, presence: true
  validates :status, presence: true

  scope :ordered, -> { order(:name) }

  def criteria_structured_data
    return {} if criteria_structured.blank?
    JSON.parse(criteria_structured)
  rescue JSON::ParserError
    {}
  end
end
