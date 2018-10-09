class SpecApp < Rails::Application
end

Rails.application = SpecApp.instance

if defined?(Rails.application.secrets)
  Rails.application.secrets.secret_key_base = 'secret'
  Rails.application.secrets.secret_token = 'secret'
end

class ActionController::Base
  def _routes
    Rails.application.routes
  end
end

Dir["#{File.dirname(__FILE__)}/../app/**/*.rb"].sort.each {|f| require f}
