ActionController::Routing::Routes.draw do |map|

  map.resource :dashboard, :member => { :error => :post }

  map.resources :songs

  map.resources :users

end
