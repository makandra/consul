module Consul
  module ActiveRecord

    private

    def authorize_values_for(property, options = {})
      if defined?(AssignableValues)
        assignable_values_for property, options.merge(:through => proc { ::Power.current })
      else
        raise "To use .authorize_values_for, add the gem 'assignable_values' to your Gemfile"
      end
    end

  end
end

ActiveSupport.on_load(:active_record) do
  extend(Consul::ActiveRecord)
end
