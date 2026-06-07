class IntegrationConnection < ApplicationRecord
  belongs_to :user

  # TODO(step 7): wrap access_token with `encrypts` once Active Record Encryption
  # keys are configured — tokens must be encrypted at rest per the plan.

  enum :provider, { github: "github", shortcut: "shortcut" }
  enum :status, { connected: "connected", stale: "stale", revoked: "revoked" }

  validates :provider, presence: true
  validates :user_id, uniqueness: { scope: :provider }
end
