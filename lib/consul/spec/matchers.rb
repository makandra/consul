module Consul
  module Spec
    module Matchers

      class CheckPower

        def initialize(*args)
          @expected_args = args
        end

        def matches?(controller)
          @controller_class = controller.class
          @actual_args = @controller_class.send(:consul_power_args)
          @actual_args.present? && @actual_args.include?(@expected_args)
        end

        def failure_message
          "expected #{@controller_class} to check against power #{@expected_args.inspect} but it checked against #{@actual_args.inspect}"
        end

        def failure_message_when_negated
          "expected #{@controller_class} to not check against power #{@expected_args.inspect}"
        end
        # Compatibility for older rspec versions
        alias_method :negative_failure_message, :failure_message_when_negated

        def description
          description = "check against power #{@expected_args.inspect}"
          description
        end

      end

      def check_power(*args)
        CheckPower.new(*args)
      end

    end
  end
end

ActiveSupport::TestCase.send :include, Consul::Spec::Matchers
