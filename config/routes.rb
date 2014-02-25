Ourbandiscalled::Application.routes.draw do
  resources :records, only: :index
  get "/:id", to: "records#short_url", constraints: { id: /\d+/ }, as: :short_url
  get "/:slug", to: "records#show", as: :slug
  root "records#new"
end
