module Api
  module V1
    # Per-user GitHub/Shortcut account connections. The token is stored encrypted
    # and never returned in responses.
    #
    # For the prototype, connecting is "paste a token" (a GitHub PAT). In real
    # Epico, GitHub would use the OAuth redirect flow and store the resulting
    # token here the same way.
    class IntegrationConnectionsController < ApplicationController
      before_action :authenticate_user!, except: :verify

      # GET /api/v1/integrations
      def index
        render_data(current_user.integration_connections.map { |c| serialize(c) })
      end

      # POST /api/v1/integrations  body: { provider, access_token, scopes? }
      def create
        provider = params.require(:provider)
        unless IntegrationConnection.providers.key?(provider)
          return render_error(code: "invalid_provider", message: "Unknown provider '#{provider}'",
                              status: :unprocessable_entity)
        end

        connection = current_user.integration_connections.find_or_initialize_by(provider: provider)
        connection.update!(
          access_token: params.require(:access_token),
          scopes: params[:scopes],
          status: "connected",
          connected_at: Time.current
        )
        render_data(serialize(connection), status: :created)
      end

      # POST /api/v1/integrations/github/verify  body: { access_token }
      # Validates a GitHub token (without storing it) and lists the repos it can see.
      def verify
        client = Integrations::Github::Client.new(token: params.require(:access_token))
        render_data({ valid: true, login: client.login, repos: client.repositories })
      rescue Integrations::Github::Client::AuthError
        render_error(code: "invalid_token", message: "Github token invalid", status: :unprocessable_entity)
      end

      # DELETE /api/v1/integrations/:provider
      def destroy
        current_user.integration_connections.find_by!(provider: params[:provider]).destroy!
        head :no_content
      end

      private

      # Note: access_token is intentionally omitted — never expose it.
      def serialize(connection)
        {
          provider: connection.provider,
          status: connection.status,
          scopes: connection.scopes,
          connected_at: connection.connected_at
        }
      end
    end
  end
end
