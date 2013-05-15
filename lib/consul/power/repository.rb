module Consul
  module Power

    class Browser
      include Memoizer

      def initialize(power, definitions)
        @power = power
        @definitions = definitions
      end

      def retrieve_collection(collection_name, *args)
        source = @definitions.collection_sources[collection_name.to_s] or raise Consul::NoCollection, "No collection \"#{collection_name}\" was defined"
        @power.instance_exec(*args, &source)
      end

      def retrieve_ids(collection_name, *args)
        collection = retrieve_collection(collection_name, *args)
        if collection.respond_to?(:collect_ids)
          self.class.database_touched
          collection.collect_ids
        else
          raise Consul::NoRelation, "Collection \"#{collection_name}\" is not a relation that can be reduced to IDs"
        end
      end

      memoize :retrieve_ids

      def collection_included?(collection_name)
        !!retrieve_collection(collection_name)
      end

      def record_included?(collection_name, record)
        collection = retrieve_collection(collection_name)
        if collection.nil?
          false
        elsif Util.scope?(collection)
          if Util.scope_selects_all_records?(collection)
            true
          else
            retrieve_ids(collection_name).include?(record.id)
          end
        elsif Util.ruby_collection?(collection)
          collection.include?(record)
        else
          raise Consul::NoCollection, "can only call #include? on a collection, but power was of type #{collection.class.name}"
        end
      end

      def self.database_touched
        # spy for tests
      end

    end

    class Definitions

      attr_reader :collection_sources, :ids_sources, :record_checkers

      def initialize
        @collection_sources = {}
        @ids_sources = {}
        @record_checkers = {}
      end

      def store_collection_source(collection_name, source)
        @collection_sources[collection_name.to_s] = source
      end

    end
  end
end
