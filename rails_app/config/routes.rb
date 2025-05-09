Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    get "/shopping_carts/:user_id", to: "shopping_carts#show"
    post "/shopping_carts/:user_id/cancel", to: "shopping_carts#cancel"
    post "/shopping_carts/:user_id/checkout", to: "shopping_carts#checkout"
    get "/shopping_carts/:user_id/current_total", to: "shopping_carts#current_total"

    post "/shopping_carts/:user_id/entries", to: "shopping_carts/entries#create"
    delete "/shopping_carts/:user_id/entries/:entry_id", to: "shopping_carts/entries#destroy"
  end
end
