class Project < ApplicationRecord
  STATUSES = %w[active completed on_hold].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
end
