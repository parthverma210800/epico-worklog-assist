class User < ApplicationRecord
  has_many :project_allocations, dependent: :destroy
  has_many :projects, through: :project_allocations

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
