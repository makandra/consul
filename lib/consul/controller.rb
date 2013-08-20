module Consul
  module Controller

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      if ensure_power_initializer_present?
        base.before_filter :ensure_power_initializer_present
      end
    end

    private

    def self.ensure_power_initializer_present?
      ['development', 'test', 'cucumber', 'in_memory'].include?(Rails.env)
    end

    module ClassMethods

      def current_power_initializer
        @current_power_initializer || (superclass.respond_to?(:current_power_initializer) && superclass.current_power_initializer)
      end

      def current_power_initializer=(initializer)
        @current_power_initializer = initializer
      end

      private

      def require_power_check(options = {})
        before_filter :unchecked_power, options
      end

      # This is badly named, since it doesn't actually skip the :check_power filter
      def skip_power_check(options = {})
        skip_before_filter :unchecked_power, options
      end

      def current_power(&initializer)
        self.current_power_initializer = initializer
        around_filter :with_current_power
        helper_method :current_power
      end

      def consul_guards
        @consul_guards ||= []
      end

      def power(*args)

        guard = Consul::Guard.new(*args)
        consul_guards << guard
        skip_power_check guard.filter_options

        # Store arguments for testing
        (@consul_power_args ||= []) << args

        before_filter :check_power, guard.filter_options

        if guard.direct_access_method
          define_method guard.direct_access_method do
            guard.power_value(self, action_name)
          end
          private guard.direct_access_method
        end

      end

    end

    module InstanceMethods

      private

      define_method :check_power do
        self.class.send(:consul_guards).each do |guard|
          guard.ensure!(self, action_name)
        end
      end

      def unchecked_power
        raise Consul::UncheckedPower, "This controller does not check against a power"
      end

      def current_power
        @current_power_class && @current_power_class.current
      end

      def with_current_power(&action)
        power = instance_eval(&self.class.current_power_initializer) or raise Consul::Error, 'current_power initializer returned nil'
        @current_power_class = power.class
        @current_power_class.current = power
        action.call
      ensure
        if @current_power_class
          @current_power_class.current = nil
        end
      end

      def ensure_power_initializer_present
        unless self.class.current_power_initializer.present?
          raise Consul::UnreachablePower, 'You included Consul::Controller but forgot to define a power using current_power do ... end'
        end
      end

    end

  end
  
end
