class User < ApplicationRecord
  has_many :project_allocations, dependent: :destroy
  has_many :projects, through: :project_allocations
  has_many :leaves, dependent: :destroy
  has_many :worklogs, dependent: :destroy
  has_many :integration_connections, dependent: :destroy
  has_many :worklog_drafts, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
