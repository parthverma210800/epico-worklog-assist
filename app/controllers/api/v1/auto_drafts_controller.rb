module Api
  module V1
    class AutoDraftsController < ApplicationController
      include SerializesWorklogDrafts

      # POST /api/v1/worklogs/auto_draft  body: { year, month }
      # Generates worklog drafts for the current user's missing days that month,
      # from their connected GitHub activity. Returns [] if no GitHub account is
      # connected. Never auto-publishes — drafts await acceptance.
      def create
        drafts = Worklogs::AutoDrafter.call(
          user: current_user,
          year: params.fetch(:year).to_i,
          month: params.fetch(:month).to_i
        )
        render_data(drafts.map { |draft| serialize_draft(draft) },
                    meta: { count: drafts.size }, status: :created)
      end
    end
  end
end
