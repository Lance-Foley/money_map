Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Resources
  resources :accounts
  resources :transactions do
    resources :transaction_splits, only: [ :create, :destroy ]
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

  # Settings
  resource :settings, only: [] do
    get "/", to: "settings#index", on: :collection
    patch :update_profile, on: :collection
    post :create_category, on: :collection
    patch "category/:id", to: "settings#update_category", as: :update_category, on: :collection
    delete "category/:id", to: "settings#destroy_category", as: :destroy_category, on: :collection
  end

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

  # Action Plan
  get "action_plan", to: "action_plan#show", as: :action_plan
  post "action_plan/generate", to: "action_plan#generate", as: :generate_action_plan
  post "action_plan/items", to: "action_plan#create_item", as: :action_plan_items
  patch "action_plan/items/:id", to: "action_plan#update_item", as: :action_plan_item
  post "action_plan/incomes", to: "action_plan#create_income", as: :action_plan_incomes
  patch "action_plan/incomes/:id", to: "action_plan#update_income", as: :action_plan_income

  # Defines the root path route ("/")
  root "pages#dashboard"
end
