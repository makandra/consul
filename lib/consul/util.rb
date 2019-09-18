module Consul
  module Util
    extend self

    def scope_selects_all_records?(scope)
      if Rails.version.to_i < 3
        scope = scope.scoped({})
      else
        scope = scope.scoped
      end
      scope_sql = scope.to_sql
      quoted_table_name = Regexp.quote(scope.connection.quote_table_name(scope.table_name))
      all_sql_pattern = /\ASELECT (#{quoted_table_name}\.)?\* FROM #{quoted_table_name}\z/
      scope_sql.squish =~ all_sql_pattern
    end

    def scope?(value)
      value.respond_to?(:scoped)
    end

    def collection?(value)
      value.is_a?(Array) || value.is_a?(Set)
    end

    def define_scope(klass, name, lambda)
      if Rails.version.to_i < 4 # Rails 2/3
        scope_definition = Rails.version.to_i < 3 ? :named_scope : :scope
        klass.send scope_definition, name, lambda
      else
        klass.send :scope, name, lambda { |*args|
          options = lambda.call(*args)
          klass.scoped(options.slice *EdgeRider::Scoped::VALID_FIND_OPTIONS)
        }
      end      
    end
    
    # This method does not support dynamic default scopes via lambdas
    # (as does #define_scope), because it is currently not required.
    def define_default_scope(klass, conditions)
      if Rails.version.to_i < 4 # Rails 2/3
        klass.send :default_scope, conditions
      else
        klass.send :default_scope do
          klass.scoped(conditions)
        end
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

    def render_ok(controller)
      if Rails.version >= '5'
        controller.render :plain => 'ok'
      else
        controller.render :text => 'ok', content_type: 'text/plain'
      end
    end

  end
end

