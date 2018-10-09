class SpecApp < Rails::Application
end

Rails.application = SpecApp.instance

if defined?(Rails.application.secrets)
  Rails.application.secrets.secret_key_base = 'secret'
  Rails.application.secrets.secret_token = 'secret'
end

Rails.application.routes.draw do
  get ':controller(/:action(/:id(.:format)))'
end

Dir["#{File.dirname(__FILE__)}/../app/controllers/**/*.rb"].sort.each {|f| require f}
Dir["#{File.dirname(__FILE__)}/../app/models/**/*.rb"].sort.each {|f| require f}
