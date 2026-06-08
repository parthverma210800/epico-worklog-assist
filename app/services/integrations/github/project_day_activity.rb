module Integrations
  module Github
    # Branch-aware activity for one user across a project's repos on a single day.
    # For each repo it lists branches (story-matching ones first, capped at
    # MAX_BRANCHES), pulls the user's commits per branch — so each commit carries
    # its branch, and thus a story even when the commit message is generic — plus
    # the PRs the user authored that day. Commits seen on multiple branches are
    # deduped by ref, keeping the story-branch occurrence (branches are prioritized).
    #
    #   Integrations::Github::ProjectDayActivity.call(client:, login:, repos:, date:)
    class ProjectDayActivity
      # Caps GitHub calls per draft. Branches beyond this are not scanned — a
      # deliberate coverage limit, not silent truncation.
      MAX_BRANCHES = 30

      def self.call(client:, login:, repos:, date:)
        new(client:, login:, repos:, date:).call
      end

      def initialize(client:, login:, repos:, date:)
        @client = client
        @login = login
        @repos = repos
        @date = date
      end

      def call
        prs = @client.pull_requests(from: @date, to: @date)
        @repos.flat_map do |repo|
          (branch_commits(repo) + prs.select { |pr| pr.repo == repo }).uniq(&:ref)
        end
      end

      private

      def branch_commits(repo)
        prioritized_branches(repo).flat_map do |branch|
          @client.commits_on(repo: repo, branch: branch, author: @login, date: @date)
        end.uniq(&:ref)
      end

      # Story-pattern branches first (so their commits win the dedupe), capped.
      def prioritized_branches(repo)
        names = @client.branches(repo).map { |b| b[:name] }
        story, other = names.partition { |name| name.match?(Activity::STORY_PATTERN) }
        (story + other).first(MAX_BRANCHES)
      end
    end
  end
end
