module Consul
  module Util
    extend self

    def scope_selects_all_records?(scope)
      scope = scope.scoped({})
      scope_sql = scope.to_sql
      quoted_table_name = Regexp.quote(scope.connection.quote_table_name(scope.table_name))
      all_sql_pattern = /\ASELECT (#{quoted_table_name}\.)?\* FROM #{quoted_table_name}\z/
      scope_sql.squish =~ all_sql_pattern
    end

    def scope?(value)
      value.respond_to?(:scoped)
    end

    def ruby_collection?(value)
      value.is_a?(Array) || value.is_a?(Set)
    end

    def define_scope(klass, name, options)
      if Rails.version.to_i < 3
        klass.send(:named_scope, name, options)
      else
        klass.send(:scope, name, options)
      end
    end

    def adjective_and_argument(*args)
      if args.size > 1
        adjective = args[0]
        record = args[1]
      else
        adjective = nil
        record = args[0]
      end
      [adjective, record]
    end

  end
end

