$: << File.join(File.dirname(__FILE__), "/../../lib" )

ENV['RAILS_ENV'] ||= 'test'
ENV['RAILS_ROOT'] = 'app_root'

FileUtils.rm(Dir.glob("app_root/db/*.db"), :force => true)

# Load the Rails environment and testing framework
Dir.chdir('app_root') do
  require "#{File.dirname(__FILE__)}/../app_root/config/environment"
end
require 'rspec/rails'
require 'rspec_candy/helpers'

# Run the migrations
ConsulMigration = ActiveRecord::Migration[5.1]
print "\033[30m" # dark gray text
ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")
print "\033[0m"

module ControllerSpecHelpers
  def wrap_params(params)
    { :params => params } # Ancient Rails/RSpec did not need the extra :params key (and our specs support them, too)
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
