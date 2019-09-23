# Matchers are not required from `require 'consul'`
require 'consul/spec/matchers'

RSpec.configure do |c|
  c.include Consul::Spec::Matchers
end

describe Consul::Spec::Matchers do

  describe '#check_power' do

    describe 'on a controller with .power directives' do

      class self::Controller < ApplicationController
        power :foo
        power :bar, only: :index
      end

      subject do
        self.class::Controller.new
      end

      it 'asserts that the controller checks the directive with the given name' do
        expect(subject).to check_power(:foo)
      end

      it 'asserts that the controller checks the directive with the given name and options' do
        expect(subject).to check_power(:bar, only: :index)
      end

      it 'asserts that the controller does not check the directive with the given name' do
        expect(subject).to_not check_power(:qux)
      end

      it 'asserts that the controller does not check the directive with the given name and options' do
        expect(subject).to_not check_power(:foo, only: :index)
      end

    end

    describe 'a controller that inherits .power directives from a parent controller' do

      class self::ParentController < ApplicationController
        power :parent
      end

      class self::ChildController < self::ParentController
        power :child
      end

      let :parent do
        self.class::ParentController.new
      end

      let :child do
        self.class::ChildController.new
      end

      it 'asserts that the child controller checks its own directives' do
        expect(child).to check_power(:child)
      end

      it 'asserts that the child controller checks the inherited directives' do
        expect(child).to check_power(:parent)
      end

      it 'does not assert that the parent checks the directives of its child' do
        expect(parent).to check_power(:parent)
        expect(parent).to_not check_power(:child)
      end

    end

  end

end