module Integrations
  module Github
    # Normalized representation of one piece of a user's GitHub activity on a day
    # (a PR, a commit, or a review). Provider-agnostic enough for the AI composer
    # to turn into a worklog line, and carries a stable source ref for traceability.
    Activity = Data.define(:kind, :repo, :ref, :title, :occurred_on, :url) do
      KINDS = %i[pull_request commit review].freeze

      # e.g. "github:org/epp:PR#11832" or "github:org/epp:commit:c7d3fb8"
      def source_ref
        "github:#{repo}:#{ref}"
      end

      def pull_request?
        kind == :pull_request
      end
    end
  end
end
