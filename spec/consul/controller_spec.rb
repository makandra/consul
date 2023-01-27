require 'spec_helper'

describe ApplicationController, :type => :controller do

  describe '.power' do

    describe 'multiple .power directives in one controller' do

      describe 'with individual :only options' do

        controller do
          power :power1, :only => :show
          power :power2, :only => :index
          power :power3

          def index
            render_nothing
          end
        end

        let :power_class do
          Class.new do
            include Consul::Power

            power :power1 do
              true
            end

            power :power2 do
              true
            end

            power :power3 do
              true
            end
          end
        end

        it 'calls the right powers' do
          power = power_class.new
          controller.stub :current_power => power

          power.should_not_receive(:power1)
          power.should_receive(:power2).at_least(:once).and_call_original
          power.should_receive(:power3).at_least(:once).and_call_original

          get :index
        end

      end

      describe 'with individual :except options' do

        controller do
          power :power1, :except => :show
          power :power2, :except => :index
          power :power3

          def index
            render_nothing
          end
        end

        let :power_class do
          Class.new do
            include Consul::Power

            power :power1 do
              true
            end

            power :power2 do
              true
            end

            power :power3 do
              true
            end
          end
        end

        it 'calls the right powers' do
          power = power_class.new
          controller.stub :current_power => power

          power.should_receive(:power1).at_least(:once).and_call_original
          power.should_not_receive(:power2)
          power.should_receive(:power3).at_least(:once).and_call_original

          get :index
        end

      end
    end

    describe 'inherited powers' do

      class self::GrandParentController < ApplicationController
        power :grand_parent

        def index
          render_nothing
        end
      end

      class self::ParentController < self::GrandParentController
        power :parent
      end

      class self::ChildController < self::ParentController
        power :child
      end

      class self::Power
        include Consul::Power

        power :grand_parent do
          true
        end

        power :parent do
          true
        end

        power :child do
          true
        end
      end

      let :power do
        self.class::Power.new
      end

      before :each do
        allow(controller).to receive(:current_power).and_return(power)
      end

      describe 'a controller that inherits from a parent with .power checks' do

        controller(self::ChildController) { }

        it 'inherits the .power checks of its ancestors' do
          expect(power).to receive(:grand_parent).at_least(:once).and_call_original
          expect(power).to receive(:parent).at_least(:once).and_call_original

          get :index
        end

        it 'may add additional power checks' do
          expect(power).to receive(:child).at_least(:once).and_call_original

          get :index
        end

      end

      describe 'the parent of a controller that defines additional .power checks' do

        controller(self::ParentController) { }

        it 'does not modify the parent powers with powers from the child' do
          expect(power).to receive(:grand_parent).at_least(:once).and_call_original
          expect(power).to receive(:parent).at_least(:once).and_call_original
          expect(power).to_not receive(:child)

          get :index
        end

      end

    end

  end

  describe '.require_power_check' do

    let :power_class do
      Class.new do
        include Consul::Power

        power :always_true do
          true
        end
      end
    end

    describe 'when a controller forgets any .power check' do

      controller do
        def index
          render_nothing
        end
      end

      it 'raises Consul::UncheckedPower and does not call the action' do
        allow(controller).to receive(:current_power).and_return(power_class.new)
        expect(controller).to_not receive(:index)
        expect { get :index }.to raise_error(Consul::UncheckedPower)
      end

    end

    describe 'when a controller has no .power check but has .skip_power_check' do

      controller do
        skip_power_check

        def index
          render_nothing
        end
      end

      it 'calls the action' do
        allow(controller).to receive(:current_power).and_return(power_class.new)
        expect(controller).to receive(:index).and_call_original
        expect { get :index }.to_not raise_error
      end

    end

    describe 'when a controller has no .power check but has .skip_power_check for another action' do

      controller do
        skip_power_check only: :show

        def index
          render_nothing
        end
      end

      it 'raises Consul::UncheckedPower and does not call the action' do
        allow(controller).to receive(:current_power).and_return(power_class.new)
        expect(controller).to_not receive(:index)
        expect { get :index }.to raise_error(Consul::UncheckedPower)
      end

    end

    describe 'when a controller has at least one .power check' do

      controller do
        power :always_true

        def index
          render_nothing
        end
      end

      it 'calls the action' do
        allow(controller).to receive(:current_power).and_return(power_class.new)
        expect(controller).to receive(:index).and_call_original
        expect { get :index }.to_not raise_error
      end

    end

    describe 'when a controller inherits at least one .power check' do

      class self::BaseController < ApplicationController
        power :always_true
      end

      controller(self::BaseController) do
        def index
          render_nothing
        end

      end

      it 'calls the action' do
        allow(controller).to receive(:current_power).and_return(power_class.new)
        expect(controller).to receive(:index).and_call_original
        expect { get :index }.to_not raise_error
      end

    end

    describe 'when a controller has at least one .power check, but :only for another action' do
      controller do
        power :always_true, only: :show

        def index
          render_nothing
        end
      end

      it 'calls the action (which might be a public action)' do
        allow(controller).to receive(:current_power).and_return(power_class.new)
        expect(controller).to receive(:index).and_call_original
        expect { get :index }.to_not raise_error
      end

    end

  end

end
