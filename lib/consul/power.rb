module Consul
  module Power
    include Consul::Power::DynamicAccess::InstanceMethods

    def self.included(base)
      base.extend ClassMethods
      base.send :include, Memoizer
    end

    def include?(name, *args)
      args = args.dup

      context, record = context_and_record_from_args(args, name)

      power_value = send(name, *context)
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
            send(power_ids_name, *context).include?(record.id)
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

    def context_and_record_from_args(args, name)
      context_count = send(self.class.context_count_name(name))
      context = []
      context_count.times do
        arg = args.shift or raise Consul::InsufficientContext, "Insufficient context for parametrized power: #{name}"
        context << arg
      end
      record = args.shift
      [context, record]
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
        context_count_method = context_count_name(name)
        define_method(context_count_method) { block.arity >= 0 ? block.arity : 0 }
        private context_count_method
        ids_method = power_ids_name(name)
        define_method(ids_method) do |*args|
          scope = send(name, *args)
          database_touched
          scope.collect_ids
        end
        memoize ids_method
        name
      end

    end

  end
end
