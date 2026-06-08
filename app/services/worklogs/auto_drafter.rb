module Worklogs
  # Orchestrates the auto-draft flow for one user and month:
  #   1. fetch the user's GitHub activity (ActivityFetcher), grouped by project+day
  #   2. keep only days that are genuinely "missing" (MissingDayResolver — the
  #      prototype stand-in for Epico's existing day classification)
  #   3. compose a draft for each (AiComposer)
  #   4. persist as suggested WorklogDraft rows (idempotent per user/project/day)
  #
  # Returns the persisted WorklogDraft records. Never writes to Worklog — drafts
  # await the engineer's acceptance (draft-and-confirm). In Epico this would run
  # as a background job; here it runs synchronously so the flow is demoable.
  #
  #   Worklogs::AutoDrafter.call(user:, year: 2026, month: 6)
  class AutoDrafter
    def self.call(user:, year:, month:, today: Date.current, github_client: nil, llm: Llm::Client.new)
      new(user:, year:, month:, today:, github_client:, llm:).call
    end

    def initialize(user:, year:, month:, today:, github_client:, llm:)
      @user = user
      @year = year
      @month = month
      @today = today
      @github_client = github_client
      @llm = llm
    end

    def call
      first = Date.new(@year, @month, 1)
      groups = ActivityFetcher.call(user: @user, from: first, to: first.end_of_month, client: @github_client)

      groups.filter_map do |group|
        next unless missing_dates_for(group.project).include?(group.date)

        draft = AiComposer.call(
          group: group,
          hours: hours_for(group.project),
          style_samples: style_samples_for(group.project),
          llm: @llm
        )
        persist(draft)
      end
    end

    private

    def missing_dates_for(project)
      @missing_dates ||= {}
      @missing_dates[project.id] ||= MissingDayResolver
                                     .call(user: @user, project: project, year: @year, month: @month, today: @today)
                                     .select { |day| day.status == :missing }
                                     .map(&:date)
                                     .to_set
    end

    def hours_for(project)
      @user.project_allocations.find_by(project: project)&.daily_hours || 8
    end

    def style_samples_for(project, limit: 2)
      @user.worklogs.where(project: project).order(work_date: :desc).limit(limit).pluck(:description)
    end

    def persist(draft)
      record = WorklogDraft.find_or_initialize_by(
        user: @user, project: draft.project, work_date: draft.date, status: "suggested"
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
