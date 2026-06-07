class Holiday < ApplicationRecord
  validates :holiday_date, presence: true, uniqueness: true
  validates :name, presence: true

  scope :on, ->(date) { where(holiday_date: date) }
end
