Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "taxes#new"
  resource :tax, only: %i[new create]
end
