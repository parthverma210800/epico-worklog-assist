module Worklogs
  # Per-project, per-day compose — the engine behind the "Auto-Draft" button on a
  # project's Add Worklog form. The project is known from context (the user is
  # inside that project's form), so we don't infer it: we fetch the user's GitHub
  # activity for the given date, keep only what maps to THIS project's repos, and
  # compose one draft entry.
  #
  # Returns the persisted WorklogDraft, or nil if there's no activity for this
  # project on that date (or no GitHub connection). Hours come from the form;
  # falls back to the user's allocation, then 8.
  #
  #   Worklogs::ComposeForDay.call(user:, project:, date: Date.new(2026,6,8), hours: 8)
  class ComposeForDay
    def self.call(user:, project:, date:, hours: nil, github_client: nil, llm: Llm::Client.new)
      new(user:, project:, date:, hours:, github_client:, llm:).call
    end

    def initialize(user:, project:, date:, hours:, github_client:, llm:)
      @user = user
      @project = project
      @date = date
      @hours = hours
      @github_client = github_client
      @llm = llm
    end

    def call
      return nil unless client

      repos = @project.project_repositories.pluck(:repo_full_name)
      return nil if repos.empty?

      activities = Integrations::Github::ProjectDayActivity.call(
        client: client, login: client.login, repos: repos, date: @date
      )
      return nil if activities.empty?

      group = ActivityFetcher::Group.new(project: @project, date: @date, activities: activities)
      draft = AiComposer.call(
        group: group,
        hours: resolved_hours,
        style_samples: style_samples,
        llm: @llm
      )
      persist(draft)
    end

    private

    def client
      @client ||= @github_client || build_client_from_connection
    end

    def build_client_from_connection
      connection = @user.integration_connections.find_by(provider: "github", status: "connected")
      return nil unless connection

      Integrations::Github::Client.new(token: connection.access_token)
    end

    def resolved_hours
      @hours || @user.project_allocations.find_by(project: @project)&.daily_hours || 8
    end

    def style_samples(limit: 2)
      @user.worklogs.where(project: @project).order(work_date: :desc).limit(limit).pluck(:description)
    end

    def persist(draft)
      record = WorklogDraft.find_or_initialize_by(
        user: @user, project: @project, work_date: @date, status: "suggested"
      )
      record.update!(
        description: draft.description,
        hours: draft.hours,
        source_refs: draft.source_refs,
        origin: "ai"
      )
      record
    end
  end
end
