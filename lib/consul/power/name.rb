module Consul
  module Power
    class Name

      attr_reader :member_name, :collection_name

      def initialize(definition_name)
        @definition_name = definition_name.to_s
        if member?
          @member_name = @definition_name.chop
          @collection_name = @member_name.pluralize
        else
          @collection_name = @definition_name
          @member_name = @collection_name.singularize
        end
      end

      def ids_name
        "#{member_name}_ids"
      end

      private

      def member?
        @definition_name.ends_with?('?')
      end

      def collection?
        !member?
      end

    end
  end
end