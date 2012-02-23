module Consul
  module Power

    def self.included(base)
      base.extend ActiveSupport::Memoizable
      base.extend ClassMethods
    end

    def include?(name, *args)
      args = args.dup
      record = args.shift
      power_value = send(name)
      if record.nil? || boolean_or_nil?(power_value)
        !!power_value
      else
        power_ids_name = self.class.power_ids_name(name)
        send(power_ids_name, *args).include?(record.id)
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

      def power(name, &block)
        define_method(name, &block)
        define_method("#{name.to_s}?") { |*args| include?(name, *args) }
        define_method("#{name.to_s}!") { |*args| include!(name, *args) }
        define_method("#{name.to_s.singularize}?") { |*args| include?(name, *args) }
        define_method("#{name.to_s.singularize}!") { |*args| include!(name, *args) }
        ids_method = power_ids_name(name)
        define_method(ids_method) do |*args|
          scope = send(name, *args)
          scope_ids = scope.scoped(:select => "`#{scope.table_name}`.`id`")
          scope_ids.collect(&:id)
        end
        memoize ids_method
        name
      end

      def power_ids_name(name)
        "#{name.to_s.singularize}_ids"
      end

      attr_accessor :current

    end

  end
end
