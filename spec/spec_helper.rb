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

begin
  require 'byebug'
rescue LoadError
  # byebug is not available for the current Gemfile
end

# Require all files in spec/support
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each {|f| require f}

Gemika::RSpec.configure_should_syntax

Gemika::RSpec.configure do |config|
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
