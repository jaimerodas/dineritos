Rails.application.routes.draw do
  root "investments#show"

  scope path_names: {new: "nuevo", edit: "editar"} do
    resources :accounts, path: "cuentas", except: [:destroy] do
      resources :account_balances, path: "saldos", only: [:new, :create]
      resource :update, path: "actualizar", only: [:show], constraints: {format: :json}
      resources :movements, path: "movimientos", only: [:index]
    end

    resources :account_balances, path: "saldos_de_cuenta", only: [:edit, :update]

    resources :balances, path: "saldos", param: :date, except: [:edit, :update]
    resource :login, path: "ingresar", only: [:show, :create]
    resource :currency, path: "tipo_de_cambio", only: [:show]
    scope module: "investments", as: "investments", path: "inversiones" do
      resource :summary, path: "resumen", only: [:show]
    end

    scope path: "graficas", as: "chart_data", module: "charts", defaults: {format: :json} do
      resource :balances, path: "saldos", only: [:show]
      resource :yields, path: "rendimientos", only: [:show]
      resources :account_balances, path: "saldos_de_cuenta", only: [:show]
      resources :account_yields, path: "rendimiento_de_cuenta", only: [:show]
    end
  end

  # Rutas directas
  get "/historial", to: "balances#index", as: "historic"
  get "/iniciar_sesion", to: "sessions#create", as: "create_session"
  get "/salir", to: "sessions#destroy", as: "logout"
end
