module Consul
  class Guard

    class ActionMap

      def initialize(default_power, custom_mappings)
        @default_power = default_power
        @map = {}
        if custom_mappings.present?
          custom_mappings.each do |action_or_actions, power|
            Array.wrap(action_or_actions).each do |action|
              action = action.to_s
              @map[action] = power
            end
          end
        end
      end

      def self.crud(resource, custom_map)
        map = {}
        map[[:show, :index]] = resource.to_sym
        map[[:new, :create]] = "creatable_#{resource}".to_sym
        map[[:edit, :update]] = "updatable_#{resource}".to_sym
        map[:destroy] = "destroyable_#{resource}".to_sym
        map = normalize_map(map).merge(normalize_map(custom_map)) # allow people to override the defaults
        new(resource, map)
      end

      def self.normalize_map(map)
        normalized_map = {}
        if map.present?
            map.each do |action_or_actions, power|
            Array.wrap(action_or_actions).each do |action|
              action = action.to_s
              normalized_map[action] = power
            end
          end
        end
        normalized_map
      end

      def power_name(action_name)
        action_name = action_name.to_s
        @map[action_name] || @default_power or raise Consul::UnmappedAction, "Could not map the action ##{action_name} to a power"
      end

    end

    def initialize(*args)

      args_copy = args.dup
      @options = args_copy.extract_options!

      default_power = args_copy.shift # might be nil

      custom_action_mappings = @options[:map]

      if @options[:crud]
        @map = ActionMap.crud(@options[:crud], custom_action_mappings)
      else
        @map = ActionMap.new(default_power, custom_action_mappings)
      end

    end

    def power_value(controller, action_name)
      repository(controller).send(*power_name_with_context(controller, action_name))
    end

    def ensure!(controller, action_name)
      repository(controller).include_power!(*power_name_with_context(controller, action_name))
    end

    def filter_options
      @options.slice(:except, :only)
    end

    def direct_access_method
      @options[:as]
    end

    private

    def power_name(action_name)
      @map.power_name(action_name)
    end

    def power_name_with_context(controller, action_name)
      [power_name(action_name), *context(controller)]
    end

    def repository(controller)
      controller.send(repository_method)
    end

    def repository_method
      @options[:power] || :current_power
    end

    def context(controller)
      context = []
      Array.wrap(@options[:context]).each do |context_method|
        arg = controller.send(context_method)
        if arg.nil?
          raise Consul::MissingContext
        end
        context << arg
      end
      context
    end

  end
end
