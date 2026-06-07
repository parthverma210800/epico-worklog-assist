# Shared JSON shape for a WorklogDraft, used by the endpoints that return drafts.
# This is the contract the Epico React UI renders against.
module SerializesWorklogDrafts
  extend ActiveSupport::Concern

  private

  def serialize_draft(draft)
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
