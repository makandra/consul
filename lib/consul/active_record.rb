module Consul
  module ActiveRecord

    private

    def authorize_values_for(property, options = {})
      if defined?(AssignableValues)
        assignable_values_for property, options.merge(:through => lambda { ::Power.current })
      else
        raise "To use .authorize_values_for, add the gem 'assignable_values' to your Gemfile"
      end
    end

  end
end

ActiveRecord::Base.send(:extend, Consul::ActiveRecord)
