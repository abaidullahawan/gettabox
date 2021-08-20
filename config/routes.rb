Rails.application.routes.draw do
  devise_for :users
  get '/home', to: 'home#index'
  root to: redirect('/home')
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
