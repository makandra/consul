require 'consul/power/name'
require 'consul/power/repository'
require 'consul/power/dynamic_access'

module Consul
  module Power
    include Consul::Power::DynamicAccess::InstanceMethods

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

    def name_for_record(*args)
      adjective, record = Util.adjective_and_argument(*args)
      name_for_model(adjective, record.class)
    end

    private

    def repository
      self.class.send(:repository)
    end

    def boolean_or_nil?(value)
      [TrueClass, FalseClass, NilClass].include?(value.class)
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
        name = Consul::Power::Name.new(name)

        repository.store_collection_source(name.collection_name, block)

        define_method(name.collection_name) do |*args|
          repository.retrieve_collection(self, name.collection_name, *args)
        end

        define_method("#{name.collection_name}?") { |*args| include?(name.collection_name, *args) }
        define_method("#{name.collection_name}!") { |*args| include!(name.collection_name, *args) }
        define_method("#{name.member_name}?") { |*args| include?(name.collection_name, *args) }
        define_method("#{name.member_name}!") { |*args| include!(name.collection_name, *args) }

        define_method(name.ids_name) do |*args|
          repository.retrieve_ids(self, name.collection_name, *args)
        end
        memoize name.ids_name
        name
      end

      def repository
        @repository ||= Consul::Power::Repository.new
      end

    end

  end
end
