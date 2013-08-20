require 'spec_helper'

describe ColorsController, :type => :controller do

  it "should allow multiple .power directives" do
    controller.stub :current_power => Power.new(:red => true, :blue => false)
    expect { get :show, :id => '1' }.to raise_error(Consul::Powerless)
    controller.stub :current_power => Power.new(:red => false, :blue => true)
    expect { get :show, :id => '1' }.to raise_error(Consul::Powerless)
    controller.stub :current_power => Power.new(:red => true, :blue => true)
    expect { get :show, :id => '1' }.to_not raise_error
  end

  it 'should be able to map multiple powers to methods' do
    controller.stub :current_power => Power.new(:red => true, :blue => false)
    controller.red_scope.should == 'red'
    controller.blue_scope.should be_nil
    controller.stub :current_power => Power.new(:red => false, :blue => true)
    controller.red_scope.should be_nil
    controller.blue_scope.should == 'blue'
  end

end
