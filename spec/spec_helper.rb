# Runtime dependencies
require 'rails/all'
require 'rspec/rails'
require 'assignable_values'

# Development dependencies
require 'rspec_candy/helpers'
require 'database_cleaner'
require 'gemika'

# Gem under test
require 'consul'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each {|f| require f}


module ControllerSpecHelpers
  def wrap_params(params)
    { :params => params  } # Specs serve multiple Rails/Rspec versions, and Controller spec syntax for params changes in later versions
  end
end

Gemika::RSpec.configure_should_syntax

Gemika::RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.include ControllerSpecHelpers
  config.include Rails.application.routes.url_helpers

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end
