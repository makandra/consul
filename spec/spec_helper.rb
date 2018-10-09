require 'gemika'

# require "active_record/railtie"
# require "action_controller/railtie"
require 'rails/all'
require 'rspec/rails'
require 'rspec_candy/helpers'
require 'assignable_values'

class SpecApp < Rails::Application
  # def routes
  #   @routes ||= ActionDispatch::Routing::RouteSet.new()
  # end
end

Rails.application = SpecApp.new
Rails.application.secrets.secret_key_base = 'secret'
Rails.application.secrets.secret_token = 'secret'
Rails.application.routes.draw do
  get ':controller(/:action(/:id(.:format)))'
end


$: << File.join(File.dirname(__FILE__), "/..lib" )
require 'consul'

Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each {|f| require f}
Dir["#{File.dirname(__FILE__)}/app/controllers/*.rb"].sort.each {|f| require f}
Dir["#{File.dirname(__FILE__)}/app/models/*.rb"].sort.each {|f| require f}

module ControllerSpecHelpers
  def wrap_params(params)
    params # Specs serve multiple Rails/Rspec versions, and Controller spec syntax for params changes in later versions
  end
end

Gemika::RSpec.configure_should_syntax

Gemika::RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.include ControllerSpecHelpers
  config.include Rails.application.routes.url_helpers
end
