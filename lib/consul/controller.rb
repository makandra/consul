module Consul
  module Controller

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      if ensure_power_initializer_present?
        Util.before_action(base, :ensure_power_initializer_present)
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
        Util.before_action(self, :unchecked_power, options)
      end

      # This is badly named, since it doesn't actually skip the :check_power filter
      def skip_power_check(options = {})
        Util.skip_before_action(self, :unchecked_power, options)
      end

      def current_power(&initializer)
        self.current_power_initializer = initializer
        Util.around_action(self, :with_current_power)

        if respond_to?(:helper_method)
          helper_method :current_power
        end
      end

      def power(*args)
        guard = Consul::Guard.new(*args)

        # One .power directive will skip the check for all actions, even
        # if that .power directive has :only or :except options.
        skip_power_check

        # Store arguments for testing
        consul_power_args << args

        Util.before_action(self, guard.filter_options) do |controller|
          guard.ensure!(controller, controller.action_name)
        end

        if guard.direct_access_method
          define_method guard.direct_access_method do
            guard.power_value(self, action_name)
          end
          private guard.direct_access_method
        end

      end

      # On first access we inherit .consul_power_args from our ancestor classes.
      # We also copy inherited args so we don't change our parent's .consul_power_args
      def consul_power_args
        unless @consul_power_args_initialized
          if superclass && superclass.respond_to?(:consul_power_args, true)
            @consul_power_args = superclass.send(:consul_power_args).dup
          else
            @consul_power_args = []
          end
          @consul_power_args_initialized = true
        end
        @consul_power_args
      end

    end

    module InstanceMethods

      private

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
