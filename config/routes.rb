Ourbandiscalled::Application.routes.draw do
  get "/:id", to: "record#short_url", constraints: { id: /\d+/ }, as: :short_url
  get "/:slug", to: "record#show", as: :slug
  root "record#new"
end
