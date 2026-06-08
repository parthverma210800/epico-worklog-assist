module Api
  module V1
    class ProjectWorklogsController < ApplicationController
      include SerializesWorklogDrafts
      before_action :authenticate_user!

      # POST /api/v1/projects/:project_id/worklogs/compose  body: { date, hours? }
      # The "Auto-Draft" button on a project's Add Worklog form: composes a draft
      # for the given date from the current user's GitHub activity in THIS
      # project's mapped repos. Returns the draft, or a message if there's no
      # matching activity (or no GitHub connection).
      def compose
        project = Project.find(params[:project_id])
        date = parse_date(params.require(:date))

        draft = Worklogs::ComposeForDay.call(
          user: current_user,
          project: project,
          date: date,
          hours: params[:hours]&.to_i
        )

        if draft
          render_data(serialize_draft(draft), status: :created)
        else
          render_data(nil, meta: { message: "No GitHub activity found for #{project.name} on #{date}" })
        end
      end

      private

      def parse_date(value)
        Date.iso8601(value)
      rescue ArgumentError
        raise ActionController::BadRequest, "date must be ISO8601 (YYYY-MM-DD)"
      end
    end
  end
end
