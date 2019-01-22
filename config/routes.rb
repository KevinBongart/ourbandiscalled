Ourbandiscalled::Application.routes.draw do
  resources :records, only: [:show], path: '/'
  root "records#new"
end
