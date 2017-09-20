Rails.application.routes.draw do
  root to: 'top#index'

  # For OmniAuth
  get '/auth/:provider/callback', to: 'sessions#callback'
  get '/auth/failure',            to: 'sessions#failure'
  get '/logout',                  to: 'sessions#destroy', as: :logout

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/confirm', to: 'top#confirm'
  post '/block', to: 'top#block'
end
