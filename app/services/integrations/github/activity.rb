module Integrations
  module Github
    # Normalized representation of one piece of a user's GitHub activity on a day
    # (a PR, a commit, or a review). Carries a stable source ref for traceability
    # and, when known, the branch it came from (used to derive the story group).
    Activity = Data.define(:kind, :repo, :ref, :title, :occurred_on, :url, :branch) do
      # branch is optional so existing callers (flat commit/PR search) still work.
      def initialize(branch: nil, **rest)
        super(branch: branch, **rest)
      end

      # e.g. "github:org/epp:PR#11832" or "github:org/epp:commit:c7d3fb8"
      def source_ref
        "github:#{repo}:#{ref}"
      end

      def pull_request?
        kind == :pull_request
      end

      # Story id from the branch (preferred), else the title, else nil.
      def story
        pattern = self.class::STORY_PATTERN
        (branch && branch[pattern, 1]) || (title && title[pattern, 1])
      end
    end

    # Assigned on the Activity class (not the enclosing module) so it loads with
    # this file and is reachable as Integrations::Github::Activity::STORY_PATTERN.
    # Extracts a Shortcut-style story id, e.g. "sc-102/initialize-db" -> "sc-102".
    Activity::STORY_PATTERN = /\b(sc-\d+)\b/i
  end
end
