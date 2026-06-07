module Worklogs
  # Promotes a suggested WorklogDraft into a real Worklog (the "Accept" action of
  # the draft-and-confirm flow), then marks the draft accepted — atomically.
  #
  #   Worklogs::AcceptDraft.call(draft: draft).worklog
  class AcceptDraft
    Result = Data.define(:worklog, :draft)

    def self.call(draft:)
      new(draft:).call
    end

    def initialize(draft:)
      @draft = draft
    end

    def call
      worklog = nil
      WorklogDraft.transaction do
        worklog = Worklog.create!(
          user: @draft.user,
          project: @draft.project,
          work_date: @draft.work_date,
          description: @draft.description,
          hours: @draft.hours
        )
        @draft.update!(status: "accepted")
      end
      Result.new(worklog: worklog, draft: @draft)
    end
  end
end
