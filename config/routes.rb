Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Resources
  resources :accounts
  resources :transactions do
    collection do
      post :bulk_categorize
    end
  end
  resources :budget_items, only: [ :create, :update, :destroy ]
  resources :incomes, only: [ :create, :update, :destroy ]
  resources :savings_goals
  resources :recurring_bills
  resources :csv_imports, only: [ :new, :create, :show ]
  resources :debts, only: [ :index, :show ]
  resources :forecasts, only: [ :index, :new, :create, :show, :destroy ]

  # Reports
  get "reports", to: "reports#index"

  # Budget (custom routing by year/month)
  get "budget(/:year/:month)", to: "budgets#show", as: :budget, defaults: { year: nil, month: nil }
  post "budget/:year/:month/copy", to: "budgets#copy_previous", as: :copy_budget

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#dashboard"
end
