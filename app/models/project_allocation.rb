class ProjectAllocation < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :daily_hours, numericality: { greater_than: 0, less_than_or_equal_to: 24 }
  validates :user_id, uniqueness: { scope: :project_id }

  scope :active, -> { where(active: true) }

  # Was this allocation in effect on the given date? start_date/end_date are
  # open-ended when nil (allocated from forever / still ongoing).
  def effective_on?(date)
    return false unless active?
    return false if start_date && date < start_date
    return false if end_date && date > end_date

    true
  end
end
