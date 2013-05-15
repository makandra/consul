module Consul
  module Power
    class Repository

      def initialize
        @collection_sources = {}
        @ids_sources = {}
        @member_checkers = {}
      end

      def retrieve_collection(context, collection_name, *args)
        source = @collection_sources[collection_name.to_s] or raise Consul::NoCollection, "No collection \"#{collection_name}\" was defined"
        context.instance_exec(*args, &source)
      end

      def retrieve_ids(context, collection_name, *args)
        collection = retrieve_collection(context, collection_name, *args)
        if collection.respond_to?(:collect_ids)
          self.class.database_touched
          collection.collect_ids
        else
          raise Consul::NoRelation, "Collection \"#{collection_name}\" is not a relation that can be reduced to IDs"
        end
      end

      def store_collection_source(collection_name, source)
        @collection_sources[collection_name.to_s] = source
      end

      def self.database_touched
        # spy for tests
      end

    end
  end
end
