$: << File.join(File.dirname(__FILE__), "/../../lib" )

ENV['RAILS_ENV'] ||= 'test'
ENV['RAILS_ROOT'] = 'app_root'

FileUtils.rm(Dir.glob("app_root/db/*.db"), :force => true)

# Load the Rails environment and testing framework
require "#{File.dirname(__FILE__)}/../app_root/config/environment"
require 'rspec/rails'
require 'rspec_candy/helpers'

# Run the migrations
ConsulMigration = ActiveRecord::Migration
print "\033[30m" # dark gray text
ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")
print "\033[0m"

module ControllerSpecHelpers
  def wrap_params(params)
    params # Specs serve multiple Rails/Rspec versions, and Controller spec syntax for params changes in later versions
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.include ControllerSpecHelpers
end
