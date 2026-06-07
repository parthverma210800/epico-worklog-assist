class Leave < ApplicationRecord
  belongs_to :user

  enum :leave_type, { full_day: "full_day", half_day: "half_day" }
  enum :status, { approved: "approved", pending: "pending" }

  validates :leave_date, presence: true

  scope :on, ->(date) { where(leave_date: date) }
end
