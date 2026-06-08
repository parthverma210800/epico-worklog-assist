module Integrations
  module Github
    # Connects a user's GitHub token and turns the repos they selected into
    # projects they're allocated to: stores the token (encrypted), and for each
    # repo ensures a Project + ProjectRepository link + ProjectAllocation exist.
    #
    # Mirrors what an Epico admin would otherwise configure; here it's self-service
    # for local testing. Idempotent — re-running with the same repos is a no-op.
    #
    #   Integrations::Github::SetupRepos.call(user:, access_token:, repo_full_names: [...])
    class SetupRepos
      def self.call(user:, access_token:, repo_full_names:)
        new(user:, access_token:, repo_full_names:).call
      end

      def initialize(user:, access_token:, repo_full_names:)
        @user = user
        @access_token = access_token
        @repo_full_names = repo_full_names
      end

      def call
        store_connection
        @repo_full_names.map { |full_name| setup_repo(full_name) }
      end

      private

      def store_connection
        connection = @user.integration_connections.find_or_initialize_by(provider: "github")
        connection.update!(access_token: @access_token, status: "connected", connected_at: Time.current)
      end

      def setup_repo(full_name)
        link = ProjectRepository.find_by(provider: "github", repo_full_name: full_name)
        project = link&.project || Project.create!(
          name: project_name(full_name), status: "active",
          project_type: "internal", start_date: Date.current
        )
        ProjectRepository.find_or_create_by!(provider: "github", repo_full_name: full_name) do |r|
          r.project = project
        end
        ProjectAllocation.find_or_create_by!(user: @user, project: project) do |a|
          a.daily_hours = 8
          a.active = true
          a.start_date = Date.current
        end
        project
      end

      # "parthverma210800/epico-worklog-assist" -> "epico-worklog-assist"
      def project_name(full_name)
        full_name.split("/").last
      end
    end
  end
end
