module Worklogs
  # Fetches a user's GitHub activity for a date range using THEIR connected token,
  # resolves each activity's repo to an Epico project (via ProjectRepository), drops
  # activity on unmapped repos, and groups the rest by [project, date] — ready for
  # the AI composer to turn into one worklog draft per project per day.
  #
  #   Worklogs::ActivityFetcher.call(user:, from:, to:)
  #   # => [#<Group project=#<Project Mocingbird> date=2026-06-05 activities=[...]>]
  #
  # A client can be injected (tests); otherwise it is built from the user's
  # connected GitHub IntegrationConnection. Returns [] if the user has no
  # connected GitHub account.
  class ActivityFetcher
    Group = Data.define(:project, :date, :activities)

    def self.call(user:, from:, to:, client: nil)
      new(user:, from:, to:, client:).call
    end

    def initialize(user:, from:, to:, client: nil)
      @user = user
      @from = from
      @to = to
      @client = client
    end

    def call
      return [] unless client

      mapped = client.activities(from: @from, to: @to).filter_map do |activity|
        project = ProjectRepository.project_for(provider: "github", repo_full_name: activity.repo)
        [project, activity] if project
      end

      mapped
        .group_by { |project, activity| [project, activity.occurred_on] }
        .map { |(project, date), pairs| Group.new(project:, date:, activities: pairs.map(&:last)) }
    end

    private

    def client
      @client ||= build_client_from_connection
    end

    def build_client_from_connection
      connection = @user.integration_connections.find_by(provider: "github", status: "connected")
      return nil unless connection

      Integrations::Github::Client.new(token: connection.access_token)
    end
  end
end
