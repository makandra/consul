Rails.application.routes.draw do
  get ':controller(/:action(/:id(.:format)))'
end
