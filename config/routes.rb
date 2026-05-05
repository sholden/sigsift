Rails.application.routes.draw do
  root "dashboard#index"

  resource :session
  resources :passwords, param: :token

  resources :opportunities do
    resources :sources
  end

  resources :leads
  resources :potential_leads, only: %i[index update]

  get "up" => "rails/health#show", as: :rails_health_check
end
