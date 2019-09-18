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
            if Rails.version >= '5'
              render :plain => 'ok'
            else
              render :text => 'ok', content_type: 'text/plain'
            end
          end
        end

        it 'calls the right powers' do

          power_class = Class.new do
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


          power = power_class.new
          controller.stub :current_power => power

          power.should_not_receive(:power1)
          power.should_receive(:power2).at_least(:once).and_call_original
          power.should_receive(:power3).at_least(:once).and_call_original

          get :index
        end

      end

    end

    describe 'with individual :except options' do

      controller do
        power :power1, :except => :show
        power :power2, :except => :index
        power :power3

        def index
          if Rails.version >= '5'
            render :plain => 'ok'
          else
            render :text => 'ok', content_type: 'text/plain'
          end
        end
      end

      it 'calls the right powers' do

        power_class = Class.new do
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

        power = power_class.new
        controller.stub :current_power => power

        power.should_receive(:power1).at_least(:once).and_call_original
        power.should_not_receive(:power2)
        power.should_receive(:power3).at_least(:once).and_call_original

        get :index
      end

    end

  end

end
