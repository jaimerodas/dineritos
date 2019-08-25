Rails.application.routes.draw do
  root "dashboards#show"

  scope path_names: {new: "nuevo", edit: "editar"} do
    resources :accounts, path: "cuentas", only: %i[index new create show]
    resources :balances, path: "saldos", param: :date
    resource :login, path: "ingresar", only: [:show, :create]
    resource :currency, path: "tipo_de_cambio", only: [:show]
  end

  # Rutas directas
  get "/historial", to: "balances#index", as: "historic"
  get "/iniciar_sesion/:token", to: "sessions#create", as: "create_session"
  get "/salir", to: "sessions#destroy", as: "logout"
end
