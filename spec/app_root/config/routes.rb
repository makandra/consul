ActionController::Routing::Routes.draw do |map|

  map.resources :properties do |properties|
    properties.resources :reviews
  end

end
