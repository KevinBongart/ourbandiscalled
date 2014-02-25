Ourbandiscalled::Application.routes.draw do
  resources "record", only: [:new, :show]
  get "/:id", to: "record#short_url", constraints: { id: /\d+/ }, as: :short_url
  get "/:slug", to: "record#show", as: :slug
  root "record#new"
end
