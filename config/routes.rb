Ourbandiscalled::Application.routes.draw do
  resources "record"
  root "record#new"
end
