module Api
  module V1
    class GithubSetupController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/github/setup  body: { access_token, repos: [full_name, ...] }
      # Stores the token and turns the selected repos into projects the user is
      # allocated to (Project + ProjectRepository + ProjectAllocation).
      def create
        projects = Integrations::Github::SetupRepos.call(
          user: current_user,
          access_token: params.require(:access_token),
          repo_full_names: Array(params[:repos])
        )
        data = projects.map { |p| { id: p.id, name: p.name } }
        render_data(data, meta: { count: data.size }, status: :created)
      end
    end
  end
end
