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
        # record is given
        if power_value.nil?
          false
        elsif Util.scope?(power_value)
          if Util.scope_selects_all_records?(power_value)
            true
          else
            power_ids_name = self.class.power_ids_name(name)
            send(power_ids_name, *args).include?(record.id)
          end
        elsif Util.collection?(power_value)
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

    module ClassMethods

      def power(*names, &block)
        names.each do |name|
          define_power(name, &block)
        end
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

      private

      def define_power(name, &block)
        define_method(name, &block)
        define_method("#{name.to_s}?") { |*args| include?(name, *args) }
        define_method("#{name.to_s}!") { |*args| include!(name, *args) }
        define_method("#{name.to_s.singularize}?") { |*args| include?(name, *args) }
        define_method("#{name.to_s.singularize}!") { |*args| include!(name, *args) }
        ids_method = power_ids_name(name)
        define_method(ids_method) do |*args|
          scope = send(name, *args)
          scope = scope.scoped(:select => "`#{scope.table_name}`.`id`")
          query = Util.scope_to_sql(scope)
          ::ActiveRecord::Base.connection.select_values(query).collect(&:to_i)
        end
        memoize ids_method
        name
      end

    end

  end
end
