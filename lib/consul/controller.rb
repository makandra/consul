module Consul
  module Controller

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      if ensure_power_initializer_present?
        if Rails.version.to_i < 4
          base.before_filter :ensure_power_initializer_present
        else
          base.before_action :ensure_power_initializer_present
        end
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
        if Rails.version.to_i < 4
          before_filter :unchecked_power, options
        else
          before_action :unchecked_power, options
        end
      end

      # This is badly named, since it doesn't actually skip the :check_power filter
      def skip_power_check(options = {})
        if Rails.version.to_i < 4
          skip_before_filter :unchecked_power, options
        elsif Rails.version.to_i < 5
          skip_before_action :unchecked_power, options
        else
          # Every `power` in a controller will skip the power check filter. After the 1st time, Rails 5+ will raise
          # an error because there is no `unchecked_power` action to skip any more.
          # To avoid this, we add the following extra option. Note that it must not be added in Rails 4 to avoid errors.
          # See http://api.rubyonrails.org/classes/ActiveSupport/Callbacks/ClassMethods.html#method-i-skip_callback
          skip_before_action :unchecked_power, { :raise => false }.merge!(options)
        end
      end

      def current_power(&initializer)
        self.current_power_initializer = initializer
        if Rails.version.to_i < 4
          around_filter :with_current_power
        else
          around_action :with_current_power
        end

        if respond_to?(:helper_method)
          helper_method :current_power
        end
      end

      attr_writer :consul_guards

      def consul_guards
        unless @consul_guards_initialized
          if superclass && superclass.respond_to?(:consul_guards, true)
            @consul_guards = superclass.send(:consul_guards).dup
          else
            @consul_guards = []
          end
          @consul_guards_initialized = true
        end
        @consul_guards
      end

      def power(*args)

        guard = Consul::Guard.new(*args)
        consul_guards << guard
        skip_power_check guard.filter_options

        # Store arguments for testing
        (@consul_power_args ||= []) << args

        if Rails.version.to_i < 4
          before_filter :check_power, guard.filter_options
        else
          before_action :check_power, guard.filter_options
        end

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
