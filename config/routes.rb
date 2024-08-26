# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get '/', to: 'home#index'
  get '*path', to: 'home#index', constraints: lambda { |request|
    !request.xhr? && request.format.html?
  }

  get '/bills', to: 'bills#index'
end
