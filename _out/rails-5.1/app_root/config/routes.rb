Rails.application.routes.draw do

  resource :dashboard do
    member { post :error }
  end

  resources :songs

  resources :users

  resources :risks

  resources :cakes do
    member { get :custom_action }
  end

  resources :colors

  resources :notes

  resources :clients do
    resources :notes
  end
  
end
