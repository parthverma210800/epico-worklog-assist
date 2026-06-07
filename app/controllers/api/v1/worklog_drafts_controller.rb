module Api
  module V1
    class WorklogDraftsController < ApplicationController
      # GET /api/v1/worklog_drafts — the current user's pending (suggested) drafts.
      def index
        drafts = current_user.worklog_drafts.pending.includes(:project).order(:work_date)
        render_data(drafts.map { |draft| serialize(draft) })
      end

      # POST /api/v1/worklog_drafts/:id/accept — promote a draft into a real worklog.
      def accept
        draft = current_user.worklog_drafts.find(params[:id])
        result = Worklogs::AcceptDraft.call(draft: draft)
        render_data({ worklog_id: result.worklog.id, draft: serialize(result.draft) }, status: :created)
      end

      private

      def serialize(draft)
        {
          id: draft.id,
          project: draft.project.name,
          work_date: draft.work_date,
          hours: draft.hours,
          description: draft.description,
          source_refs: draft.source_refs,
          origin: draft.origin,
          status: draft.status
        }
      end
    end
  end
end
