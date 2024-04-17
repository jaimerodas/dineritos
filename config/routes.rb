Rails.application.routes.draw do
  root "investments#show"

  scope path_names: {new: "nuevo", edit: "editar"} do
    resources :accounts, path: "cuentas", except: [:destroy] do
      resources :account_balances, path: "saldos", only: [:new, :create]
      resource :update, path: "actualizar", only: [:show], constraints: {format: :json}
      resources :movements, path: "movimientos", only: [:index]
    end

    resource :settings, path: "opciones", only: [:show, :create]
    resources :passkeys, only: [:new, :create] do
      post :callback, on: :collection
    end
    resources :missing_balances, path: "saldos_faltantes", only: [:index]
    resources :account_balances, path: "saldos_de_cuenta", only: [:edit, :update]

    resource :login, path: "ingresar", only: [:show, :create] do
      get :choose, path: "escoge", on: :collection
      get :email, on: :collection
      post :passkey, on: :collection
      post :callback, on: :collection
    end
    resource :currency, path: "tipo_de_cambio", only: [:show]
    scope module: "investments", as: "investments", path: "inversiones" do
      resource :summary, path: "resumen", only: [:show]
    end

    scope path: "graficas", as: "chart_data", module: "charts", defaults: {format: :json} do
      resource :balances, path: "saldos", only: [:show]
      resource :yields, path: "rendimientos", only: [:show]
    end

    scope path: "reportes", module: "reports", as: "reports" do
      resource :dailies, path: "diarios", only: [:show]
    end
  end

  # Rutas directas
  get "/iniciar_sesion", to: "sessions#create", as: "create_session"
  get "/salir", to: "sessions#destroy", as: "logout"
end
