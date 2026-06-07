class ProjectRepository < ApplicationRecord
  belongs_to :project

  # Code hosts only (Shortcut is a PM tool, not a code host). Extensible to gitlab/bitbucket.
  enum :provider, { github: "github" }

  validates :repo_full_name, presence: true,
                             uniqueness: { scope: :provider, case_sensitive: false }

  # Resolve a repo full-name (e.g. "org/epp") to its mapped project.
  def self.project_for(provider:, repo_full_name:)
    find_by(provider: provider, repo_full_name: repo_full_name)&.project
  end
end
