class WorklogDraft < ApplicationRecord
  belongs_to :user
  belongs_to :project

  enum :origin, { deterministic: "deterministic", ai: "ai" }
  enum :status, { suggested: "suggested", accepted: "accepted", dismissed: "dismissed" }

  validates :work_date, presence: true

  scope :pending, -> { where(status: "suggested") }
end
