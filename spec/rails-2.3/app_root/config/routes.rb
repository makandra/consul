ActionController::Routing::Routes.draw do |map|

  map.resource :dashboard, :member => { :error => :post }

  map.resources :songs

  map.resources :users

  map.resources :risks

  map.resources :cakes, :member => { :custom_action => :get }

  map.resources :colors

  map.resources :notes

  map.resources :clients do
    map.resources :notes
  end

end
