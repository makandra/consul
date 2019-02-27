module Consul
  module Power
    include Consul::Power::DynamicAccess::InstanceMethods

    def self.included(base)
      base.extend ClassMethods
      base.send :include, Memoized
    end

    private

    def default_include_power?(power_name, *context)
      result = send(power_name, *context)
      # Everything that is not nil is considered as included.
      # We are short-circuiting for #scoped first since sometimes
      # has_many associations (which behave scopish) trigger their query
      # when you try to negate them, compare them or even retrieve their
      # class. Unfortunately we can only reproduce this in live Rails
      # apps, not in Consul tests. Might be some standard gem that is not
      # loaded in Consul tests.
      result.respond_to?(:load_target, true) || !!result
    end

    def default_include_object?(power_name, *args)
      check_number_of_arguments_in_include_object(power_name, args.length)
      object = args.pop
      context = args
      power_value = send(power_name, *context)
      if power_value.nil?
        false
      elsif Util.scope?(power_value)
        if Util.scope_selects_all_records?(power_value)
          true
        else
          power_ids_name = self.class.power_ids_name(power_name)
          send(power_ids_name, *context).include?(object.id)
        end
      elsif Util.collection?(power_value)
        power_value.include?(object)
      else
        raise Consul::NoCollection, "can only call #include_object? on a collection, but power was of type #{power_value.class.name}"
      end
    end

    def default_power_ids(power_name, *args)
      scope = send(power_name, *args)
      database_touched
      scope.collect_ids
    end

    def powerless!(*args)
      raise Consul::Powerless.new("No power to #{[*args].inspect}")
    end

    def boolean_or_nil?(value)
      [TrueClass, FalseClass, NilClass].include?(value.class)
    end

    def database_touched
      # spy for tests
    end

    def singularize_power_name(name)
      self.class.singularize_power_name(name)
    end

    def check_number_of_arguments_in_include_object(power_name, given_arguments)
      # check unmemoized methods as Memoizer wraps methods and masks the arity.
      unmemoized_power_name = respond_to?("_unmemoized_#{power_name}") ? "_unmemoized_#{power_name}" : power_name
      power_arity = method(unmemoized_power_name).arity
      expected_arity = power_arity + 1 # one additional argument for the context
      if power_arity >= 0 && expected_arity != given_arguments
        raise ArgumentError.new("wrong number of arguments (given #{given_arguments}, expected #{expected_arity})")
      end
    end

    module ClassMethods
      include Consul::Power::DynamicAccess::ClassMethods

      def power(*names, &block)
        names.each do |name|
          define_power(name, &block)
        end
      end

      def power_ids_name(name)
        "#{name.to_s.singularize}_ids"
      end

      def self.thread_key(klass)
        "consul|#{klass.to_s}.current"
      end

      def current
        Thread.current[ClassMethods.thread_key(self)]
      end

      def current=(power)
        Thread.current[ClassMethods.thread_key(self)] = power
      end

      def with_power(inner_power, &block)
        unless inner_power.is_a?(self) || inner_power.nil?
          inner_power = new(inner_power)
        end
        old_power = current
        self.current = inner_power
        block.call
      ensure
        self.current = old_power
      end

      def without_power(&block)
        with_power(nil, &block)
      end

      def define_query_and_bang_methods(name, options, &query)
        is_plural = options.fetch(:is_plural)
        query_method = "#{name}?"
        bang_method = "#{name}!"
        define_method(query_method, &query)
        memoize query_method
        define_method(bang_method) do |*args|
          if is_plural
            if send(query_method, *args)
              send(name, *args)
            else
              powerless!(name, *args)
            end
          else
            send(query_method, *args) or powerless!(name, *args)
          end
        end
        # We don't memoize the bang method since memoizer can't memoize a thrown exception
      end

      def define_ids_method(name)
        ids_method = power_ids_name(name)
        define_method(ids_method) { |*args| default_power_ids(name, *args) }
        # Memoize `ids_method` in addition to the collection method itself, since
        # #default_include_object? directly accesses `ids_method`.
        memoize ids_method
      end

      def define_main_method(name, &block)
        define_method(name, &block)
        memoize name
      end

      def define_power(name, &block)
        name = name.to_s
        if name.ends_with?('?')
          # The developer is trying to register an optimized query method
          # for singular object queries.
          name_without_suffix = name.chop
          define_query_and_bang_methods(name_without_suffix, :is_plural => false, &block)
        else
          define_main_method(name, &block)
          define_ids_method(name)
          define_query_and_bang_methods(name, :is_plural => true) { |*args| default_include_power?(name, *args) }
          begin
            singular = singularize_power_name(name)
            define_query_and_bang_methods(singular, :is_plural => false) { |*args| default_include_object?(name, *args) }
          rescue Consul::PowerNotSingularizable
            # We do not define singularized power methods if it would
            # override the collection method
          end
        end
        name
      end

      def singularize_power_name(name)
        name = name.to_s
        singularized = name.singularize
        if singularized == name
          raise Consul::PowerNotSingularizable, "Power name can not have an singular form: #{name}"
        else
          singularized
        end
      end

    end
  end
end
