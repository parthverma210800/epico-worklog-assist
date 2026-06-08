require "base64"
require "json"

module Auth
  # Decodes an Epico Bearer JWT and returns its identity claims. Epico signs the
  # token (RS256); it carries `sub` (email) and `uuid` (resourceId) which we use
  # to resolve/verify the user.
  #
  #   Auth::EpicoToken.decode(request.headers["Authorization"]).email  # => "parth.verma@..."
  #
  # NOTE(prototype): the signature is NOT cryptographically verified here — that
  # requires Epico's RS256 public key (JWKS via the token's `kid`). Production MUST
  # verify the signature; this decode-only step trusts the payload for local testing.
  module EpicoToken
    Claims = Data.define(:email, :resource_id, :authorities, :expires_at)

    class InvalidToken < StandardError; end

    module_function

    def decode(authorization_header)
      token = authorization_header.to_s.sub(/\ABearer\s+/i, "").strip
      raise InvalidToken, "missing bearer token" if token.empty?

      segment = token.split(".")[1]
      raise InvalidToken, "malformed token" if segment.nil?

      payload = JSON.parse(Base64.urlsafe_decode64(pad(segment)))
      claims = Claims.new(
        email: payload["sub"],
        resource_id: payload["uuid"],
        authorities: payload["authorities"],
        expires_at: payload["exp"] && Time.at(payload["exp"])
      )
      raise InvalidToken, "token expired" if claims.expires_at && claims.expires_at < Time.current
      raise InvalidToken, "no subject (email) in token" if claims.email.blank?

      claims
    rescue ArgumentError, JSON::ParserError
      raise InvalidToken, "malformed token"
    end

    def pad(base64url)
      base64url + ("=" * ((4 - (base64url.length % 4)) % 4))
    end
  end
end
