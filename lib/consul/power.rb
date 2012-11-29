module Consul
  module Power

    def self.included(base)
      base.extend ClassMethods
      base.send :include, Memoizer
    end

    def include?(name, *args)
      args = args.dup
      record = args.shift
      power_value = send(name)
      if record.nil?
        !!power_value
      else
        if scope?(power_value)
          power_ids_name = self.class.power_ids_name(name)
          send(power_ids_name, *args).include?(record.id)
        elsif collection?(power_value)
          power_value.include?(record)
        else
          raise Consul::NoCollection, "can only call #include? on a collection, but power was of type #{power_value.class.name}"
        end
      end
    end

    def include!(*args)
      include?(*args) or raise Consul::Powerless.new("No power to #{args.inspect}")
    end

    private

    def boolean_or_nil?(value)
      [TrueClass, FalseClass, NilClass].include?(value.class)
    end

    def scope?(value)
      value.respond_to?(:scoped)
    end

    def collection?(value)
      value.is_a?(Array) || value.is_a?(Set)
    end

    module ClassMethods

      def power(name, &block)
        define_method(name, &block)
        define_method("#{name.to_s}?") { |*args| include?(name, *args) }
        define_method("#{name.to_s}!") { |*args| include!(name, *args) }
        define_method("#{name.to_s.singularize}?") { |*args| include?(name, *args) }
        define_method("#{name.to_s.singularize}!") { |*args| include!(name, *args) }
        ids_method = power_ids_name(name)
        define_method(ids_method) do |*args|
          scope = send(name, *args)
          scope = scope.select(:"#{scope.primary_key}")
          query = if scope.respond_to?(:to_sql)
            scope.to_sql
          else
            scope.construct_finder_sql({})
          end
          ::ActiveRecord::Base.connection.select_values(query)
        end
        memoize ids_method
        name
      end

      def power_ids_name(name)
        "#{name.to_s.singularize}_ids"
      end

      attr_accessor :current

      def with_power(inner_power, &block)
        unless inner_power.is_a?(self)
          inner_power = new(inner_power)
        end
        old_power = current
        self.current = inner_power
        block.call
      ensure
        self.current = old_power
      end

    end

  end
end
