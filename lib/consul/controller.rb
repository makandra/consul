module Consul
  module Controller

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods

      attr_accessor :current_power_initializer

      private

      def require_power_check(options = {})
        before_filter :unchecked_power, options
      end

      def skip_power_check(options = {})
        skip_before_filter :unchecked_power, options
      end

      def current_power(&initializer)
        self.current_power_initializer = initializer
        around_filter :with_current_power
      end

      def power(*args)

        args_copy = args.dup
        options = args_copy.extract_options!
        default_power = args_copy.shift # might be nil

        filter_options = options.slice(:except, :only)
        skip_power_check filter_options

        power_method = options[:power] || :current_power
        actions_map = (options[:map] || {})

        direct_access_method = options[:as]

        # Store arguments for testing
        @consul_power_args = args

        before_filter :check_power, filter_options

        private

        define_method :check_power do
          send(power_method).include!(power_for_action)
        end

        define_method direct_access_method do
          send(power_method).send(power_for_action)
        end if direct_access_method

        define_method :power_for_action do
          key = actions_map.keys.detect do |actions|
            Array(actions).collect(&:to_s).include?(action_name)
          end
          if key
            actions_map[key]
          elsif default_power
            default_power
          else
            raise Consul::UnmappedAction, "Could not map the action ##{action_name} to a power"
          end
        end

      end

    end

    module InstanceMethods

      private

      attr_accessor :current_power

      def unchecked_power
        raise Consul::UncheckedPower, "This controller does not check against a power"
      end

      def with_current_power(&action)
        p self.class.current_power_initializer
        self.current_power = instance_eval(&self.class.current_power_initializer)
        action.call
      ensure
        self.current_power = nil
      end

    end

  end
  
end
