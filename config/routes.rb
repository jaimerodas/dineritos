Rails.application.routes.draw do
  root "investments#show"

  scope path_names: {new: "nuevo", edit: "editar"} do
    resources :accounts, path: "cuentas", except: [:destroy] do
      resources :account_balances, path: "saldos", only: [:new, :create]
      resource :update, path: "actualizar", only: [:show], constraints: {format: :json}
      resources :movements, path: "movimientos", only: [:index]
      resource :statistics, path: "estadisticas", only: [:show]
      get "/reset", to: "accounts#reset", as: "reset"
    end

    resource :settings, path: "opciones", only: [:show, :create]
    resources :passkeys, only: [:new, :create, :destroy] do
      post :callback, on: :collection
    end
    resources :missing_balances, path: "saldos_faltantes", only: [:index]
    resources :account_balances, path: "saldos_de_cuenta", only: [:edit, :update]

    resource :login, path: "ingresar", only: [:show, :create] do
      # Email-based login (magic link)
      get :email, on: :collection
      # Passkey authentication: discovery mode (no email) and email-based fallback
      get :discovery, on: :collection, defaults: {format: :json}
      # Remove email-identified passkey route (no longer used)
      post :callback, on: :collection
    end
    # Standalone page for USD/MXN exchange rate
    resource :exchange_rate, path: "tipo_de_cambio", controller: "exchange_rates", only: [:show]
    scope module: "investments", as: "investments", path: "inversiones" do
      resource :summary, path: "resumen", only: [:show]
    end

    scope path: "graficas", as: "chart_data", module: "charts", defaults: {format: :json} do
      resource :balances, path: "saldos", only: [:show]
      resource :yields, path: "rendimientos", only: [:show]
      # USD/MXN exchange rate over time
      # JSON endpoint for exchange rate series
      resource :exchange_rate, path: "tipo_de_cambio", controller: "exchange_rates", only: [:show]
    end

    scope path: "reportes", module: "reports", as: "reports" do
      resource :dailies, path: "diarios", only: [:show]
      resource :statements, path: "estados_de_cuenta", only: [:show]
    end
  end

  # Health check for Kamal / load balancer
  get "up" => "rails/health#show", :as => :rails_health_check

  # Rutas directas
  get "/iniciar_sesion", to: "sessions#create", as: "create_session"
  get "/salir", to: "sessions#destroy", as: "logout"
end
