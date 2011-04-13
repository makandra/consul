ActionController::Routing::Routes.draw do |map|

  map.resource :dashboard

  map.resources :songs

  map.resources :users

end
