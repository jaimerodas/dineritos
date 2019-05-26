Rails.application.routes.draw do
  root "dashboards#show"

  resources :accounts, only: %i[index new create]
  resources :balances, param: :date
end
