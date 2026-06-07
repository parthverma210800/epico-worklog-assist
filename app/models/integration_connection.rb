class IntegrationConnection < ApplicationRecord
  belongs_to :user

  # Encrypted at rest (keys in config/initializers/active_record_encryption.rb).
  encrypts :access_token

  enum :provider, { github: "github", shortcut: "shortcut" }
  enum :status, { connected: "connected", stale: "stale", revoked: "revoked" }

  validates :provider, presence: true
  validates :user_id, uniqueness: { scope: :provider }
end
