class Project < ApplicationRecord
  STATUSES = %w[active completed on_hold].freeze

  has_many :project_allocations, dependent: :destroy
  has_many :users, through: :project_allocations
  has_many :worklogs, dependent: :destroy
  has_many :project_repositories, dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
end
