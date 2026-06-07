module Api
  module V1
    class WorklogDraftsController < ApplicationController
      include SerializesWorklogDrafts

      # GET /api/v1/worklog_drafts — the current user's pending (suggested) drafts.
      def index
        drafts = current_user.worklog_drafts.pending.includes(:project).order(:work_date)
        render_data(drafts.map { |draft| serialize_draft(draft) })
      end

      # POST /api/v1/worklog_drafts/:id/accept — promote a draft into a real worklog.
      def accept
        draft = current_user.worklog_drafts.find(params[:id])
        result = Worklogs::AcceptDraft.call(draft: draft)
        render_data({ worklog_id: result.worklog.id, draft: serialize_draft(result.draft) }, status: :created)
      end
    end
  end
end
