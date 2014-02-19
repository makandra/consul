module Consul
  module Power
    module DynamicAccess

      module InstanceMethods

        def include?(power_name, *args)
          warn "makandra/consul: #include? ist deprececated. Use #include_power? and #include_object? instead."
          if args.size == 0
            include_power?(power_name, *args)
          else
            include_object?(power_name, *args)
          end
        end

        def include!(power_name, *args)
          warn "makandra/consul: #include! ist deprececated. Use #include_power! and #include_object! instead."
          if args.size == 0
            include_power!(power_name, *args)
          else
            include_object!(power_name, *args)
          end
        end

        def include_power?(power_name, *context)
          send("#{power_name}?", *context)
        end

        def include_power!(power_name, *context)
          send("#{power_name}!", *context)
        end

        def include_object?(power_name, *context_and_object)
          power_name = power_name.to_s
          send("#{power_name.singularize}?", *context_and_object)
        end

        def include_object!(power_name, *context_and_object)
          power_name = power_name.to_s
          send("#{power_name.singularize}!", *context_and_object)
        end

        def for_record(*args)
          send(name_for_record(*args))
        end

        def include_record?(*args)
          adjective, record = Util.adjective_and_argument(*args)
          include_object?(name_for_record(*args), record)
        end

        def include_record!(*args)
          adjective, record = Util.adjective_and_argument(*args)
          include_object!(name_for_record(*args), record)
        end

        def name_for_model(*args)
          adjective, model_class = Util.adjective_and_argument(*args)
          collection_name = model_class.name.underscore.gsub('/', '_').pluralize
          [adjective, collection_name].select(&:present?).join('_')
        end

        def for_model(*args)
          send(name_for_model(*args))
        end

        def include_model?(*args)
          include_power?(name_for_model(*args))
        end

        def include_model!(*args)
          include_power!(name_for_model(*args))
        end

        def name_for_record(*args)
          adjective, record = Util.adjective_and_argument(*args)
          name_for_model(adjective, record.class)
        end

      end

      module ClassMethods

        def for_model(*args)
          if current
            current.for_model(*args)
          else
            adjective, model = Util.adjective_and_argument(*args)
            model
          end
        end

        def include_model?(*args)
          if current
            current.include_model?(*args)
          else
            true
          end
        end

        def include_model!(*args)
          if current
            current.include_model!(*args)
          else
            true
          end
        end

        def for_record(*args)
          if current
            current.for_record(*args)
          else
            adjective, record = Util.adjective_and_argument(*args)
            record.class
          end
        end

        def include_record?(*args)
          if current
            current.include_record?(*args)
          else
            true
          end
        end

        def include_record!(*args)
          if current
            current.include_record!(*args)
          else
            true
          end
        end

      end

    end
  end
end
