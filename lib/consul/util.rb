module Consul
  module Util
    extend self

    def scope_selects_all_records?(scope)
      scope = scope.scoped
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
      klass.send :scope, name, lambda { |*args|
        options = lambda.call(*args)
        klass.scoped(options.slice *EdgeRider::Scoped::VALID_FIND_OPTIONS)
      }
    end

    # This method does not support dynamic default scopes via lambdas
    # (as does #define_scope), because it is currently not required.
    def define_default_scope(klass, conditions)
      klass.send :default_scope do
        klass.scoped(conditions)
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

    def skip_before_action(controller_class, name, options)
      # Every `power` in a controller will skip the power check filter. After the 1st time, Rails will raise
      # an error because there is no `unchecked_power` action to skip any more.
      # To avoid this, we add the following extra option.
      # See http://api.rubyonrails.org/classes/ActiveSupport/Callbacks/ClassMethods.html#method-i-skip_callback
      controller_class.skip_before_action name, { :raise => false }.merge!(options)
    end

    def before_action(controller_class, *args, &block)
      controller_class.before_action *args, &block
    end

    def around_action(controller_class, *args, &block)
      controller_class.around_action *args, &block
    end

  end
end

