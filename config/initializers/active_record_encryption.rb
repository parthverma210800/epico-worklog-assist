# Active Record Encryption keys, used to encrypt IntegrationConnection#access_token
# at rest. The DEV/TEST fallbacks below keep the prototype runnable out of the box.
#
# In real Epico: set these via ENV (or Rails credentials) and NEVER commit the
# production keys. Generate fresh ones with `bin/rails db:encryption:init`.
Rails.application.configure do
  enc = config.active_record.encryption
  enc.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "dev_only_primary_key_change_in_production_01")
  enc.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "dev_only_deterministic_key_change_prod_02")
  enc.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "dev_only_key_derivation_salt_change_prod_03")
end
