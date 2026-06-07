class ProjectAllocation < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :daily_hours, numericality: { greater_than: 0, less_than_or_equal_to: 24 }
  validates :user_id, uniqueness: { scope: :project_id }

  scope :active, -> { where(active: true) }
end
