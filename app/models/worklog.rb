class Worklog < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :work_date, presence: true
  validates :description, presence: true
  validates :hours, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 24 }

  scope :for_month, lambda { |year, month|
    start_date = Date.new(year, month, 1)
    where(work_date: start_date..start_date.end_of_month)
  }
end
