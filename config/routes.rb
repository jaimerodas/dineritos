Rails.application.routes.draw do
  root "dashboards#show"

  resources :accounts, only: %i[index new create show]
  resources :balances, param: :date
  resource :login, only: [:show, :create]
  get "/create_session/:token", to: "sessions#create", as: "create_session"
end
