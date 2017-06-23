$: << File.join(File.dirname(__FILE__), "/../../lib" )

# Set the default environment to sqlite3's in_memory database
ENV['RAILS_ENV'] = 'in_memory'

FileUtils.rm(Dir.glob("db/*.db"), :force => true)

# Load the Rails environment and testing framework
require "#{File.dirname(__FILE__)}/../app_root/config/environment"
require 'spec/rails'

require 'rspec_candy/helpers'

# Undo changes to RAILS_ENV
silence_warnings {RAILS_ENV = ENV['RAILS_ENV']}

# Requires supporting files with custom matchers and macros, etc in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

# Run the migrations
ConsulMigration = ActiveRecord::Migration
print "\033[30m" # dark gray text
ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")
print "\033[0m"

module ControllerSpecHelpers
  def wrap_params(params)
    params
  end
end

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.include ControllerSpecHelpers
end
