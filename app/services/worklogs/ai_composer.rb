module Worklogs
  # Turns one day's GitHub activity for one project (an ActivityFetcher::Group)
  # into a structured worklog draft, via the LLM. Optionally takes the engineer's
  # recent entries as a style anchor and free-text rough notes to incorporate.
  #
  # Returns a Draft value object (not persisted — the caller/job persists it as a
  # WorklogDraft). The LLM client is injectable for tests.
  #
  #   Worklogs::AiComposer.call(group: group, hours: 8)
  class AiComposer
    Draft = Data.define(:project, :date, :description, :hours, :source_refs)

    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are a worklog assistant for a software engineer. Given the engineer's
      GitHub activity for a single day on a single project, write a concise but
      detailed worklog entry in their established style: group work by story,
      use short numbered steps describing what was done, and reference story IDs,
      PR numbers, and commits where present. Output ONLY the worklog text — no
      preamble, no headings, no closing commentary.
    PROMPT

    def self.call(group:, hours: 8, style_samples: [], rough_notes: nil, llm: Llm.default)
      new(group:, hours:, style_samples:, rough_notes:, llm:).call
    end

    def initialize(group:, hours:, style_samples:, rough_notes:, llm:)
      @group = group
      @hours = hours
      @style_samples = style_samples
      @rough_notes = rough_notes
      @llm = llm
    end

    def call
      description = @llm.complete(system: SYSTEM_PROMPT, user: user_prompt)

      Draft.new(
        project: @group.project,
        date: @group.date,
        description: description,
        hours: @hours,
        source_refs: @group.activities.map(&:source_ref)
      )
    end

    private

    def user_prompt
      lines = ["Project: #{@group.project.name}", "Date: #{@group.date}", "", "GitHub activity:"]
      @group.activities.each { |a| lines << "- [#{a.kind}] #{a.ref} — #{a.title}" }

      if @rough_notes.present?
        lines += ["", "Engineer's rough notes (incorporate these):", @rough_notes]
      end

      if @style_samples.any?
        lines += ["", "Recent worklog entries (match this style and tone):", *@style_samples]
      end

      lines.join("\n")
    end
  end
end
