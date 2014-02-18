module Consul
  module Power
    include Consul::Power::DynamicAccess::InstanceMethods

    def self.included(base)
      base.extend ClassMethods
    end

    def allowed(&block)
      AllowedProc.new(&block)
    end

    private

    def default_include_power?(power_name, *context)
      result = send(power_name, *context)
      # Everything that is not nil is considered as included.
      # Check for scopes, since sometimes has_many association that look scopish
      # can trigger queries, even when negating them
      looks_like_a_scope?(result) || !!result
    end

    def looks_like_a_scope?(maybe_scope)
      maybe_scope.respond_to?(:load_target, true)
    end

    def default_include_object?(power_name, *args)
      object = args.pop
      context = args
      power_value = send(power_name, *context)
      if power_value.nil?
        false
      elsif Util.scope?(power_value)
        if Util.scope_selects_all_records?(power_value)
          true
        else
          cached_default_power_ids(power_name, power_value, *context).include?(object.id)
        end
      elsif Util.collection?(power_value)
        power_value.include?(object)
      else
        raise Consul::NoCollection, "can only call #include_object? on a collection, but power was of type #{power_value.class.name}"
      end
    end

    def cached_default_power_ids(power_name, scope, *args)
      key = [power_name] + args
      @_default_power_ids ||= {}
      cached = @_default_power_ids[key]
      if cached.nil?
        power_ids = default_power_ids(power_name, scope, *args)
        @_default_power_ids[key] = power_ids
        power_ids
      else
        cached
      end
    end

    def default_power_ids(power_name, scope, *args)
      scope ||= send(power_name, *args)
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

    module ClassMethods
      include Consul::Power::DynamicAccess::ClassMethods

      def power(*names, &block)
        names.each do |name|
          define_power(name, &block)
        end
      end

      def context_count_name(name)
        "#{name}_context_count"
      end

      def power_ids_name(name)
        "#{name.to_s.singularize}_ids"
      end

      attr_accessor :current

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

      def define_query_and_bang_methods(name, &query)
        query_method = "#{name}?"
        bang_method = "#{name}!"
        define_method(query_method, &query)
        define_method(bang_method) { |*args| send(query_method, *args) or powerless!(name, *args) }
      end

      # unwrap AllowedProcs
      def define_power_method(name, raw_power_name)
        define_method(name) do |*args|
          result = send(raw_power_name, *args)
          if !looks_like_a_scope?(result) and result.is_a?(AllowedProc)
            instance_exec(&result)
          else
            result
          end
        end
      end

      def define_power(name, &block)
        name = name.to_s
        raw_power_name = "_raw_#{name}"
        if name.ends_with?('?')
          name_without_suffix = name.chop
          define_query_and_bang_methods(name_without_suffix, &block)
        else
          define_method(raw_power_name, &block)
          define_power_method(name, raw_power_name)
          define_query_and_bang_methods(name) { |*args| default_include_power?(raw_power_name, *args) }
          if name.singularize != name
            define_query_and_bang_methods(name.singularize) { |*args| default_include_object?(name, *args) }
          end
          ids_method = power_ids_name(name)
          define_method(ids_method) { |*args| cached_default_power_ids(name, nil, *args) }
        end
        name
      end

    end
  end
end
