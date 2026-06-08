Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :worklog_drafts, only: :index do
        member { post :accept }
      end
      post "worklogs/auto_draft", to: "auto_drafts#create"
      post "projects/:project_id/worklogs/compose", to: "project_worklogs#compose"

      get "integrations", to: "integration_connections#index"
      post "integrations", to: "integration_connections#create"
      delete "integrations/:provider", to: "integration_connections#destroy"
    end
  end
end
