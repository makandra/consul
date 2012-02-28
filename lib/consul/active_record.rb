module Consul
  module ActiveRecord

    private

    def authorize_values_for(property, options = {})
      assignable_values_for property, options.merge(:through => lambda { ::Power.current })
    end

  end
end

ActiveRecord::Base.send(:extend, Consul::ActiveRecord)
