Rails.application.routes.draw do

  devise_for :users
  # get 'pages/home'
  root to: 'articles#index'

  resources :articles, only: [:index, :show, :create, :new]

end
