require 'consul/power/name'
require 'consul/power/repository'
require 'consul/power/dynamic_access'

module Consul
  module Power
    include Consul::Power::DynamicAccess::InstanceMethods

    def self.included(base)
      base.extend ClassMethods
      #base.send :include, Memoizer
    end

    def include?(name, *args)
      args = args.dup
      record = args.shift
      if record.nil?
        browser.collection_included?(name)
      else
        browser.record_included?(name, record)
      end
    end

    def include!(*args)
      include?(*args) or raise Consul::Powerless.new("No power to #{args.inspect}")
    end

    private

    def browser
      @browser ||= Browser.new(self, self.class.send(:definitions))
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

        definitions.store_collection_source(name.collection_name, block)

        define_method(name.collection_name) do |*args|
          browser.retrieve_collection(name.collection_name, *args)
        end

        define_method("#{name.collection_name}?") do |*args|
          include?(name.collection_name)
        end

        define_method("#{name.collection_name}!") do |*args|
          include!(name.collection_name, *args)
        end

        define_method("#{name.member_name}?") do |*args|
          include?(name.collection_name, *args)
        end

        define_method("#{name.member_name}!") do |*args|
          include!(name.collection_name, *args)
        end

        define_method(name.ids_name) do |*args|
          browser.retrieve_ids(name.collection_name, *args)
        end
        #memoize name.ids_name
        name
      end

      def definitions
        @definitions ||= Consul::Power::Definitions.new
      end

    end

  end
end
