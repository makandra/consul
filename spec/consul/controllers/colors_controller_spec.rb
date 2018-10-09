require 'spec_helper'

describe ColorsController, :type => :controller do

  it "should allow multiple .power directives" do
    controller.stub :current_power => Power.new(:red => true, :blue => false)
    expect { get :show, { :params => { :id => '1' } } }.to raise_error(Consul::Powerless)
    controller.stub :current_power => Power.new(:red => false, :blue => true)
    expect { get :show, { :params => { :id => '1' } } }.to raise_error(Consul::Powerless)
    controller.stub :current_power => Power.new(:red => true, :blue => true)
    expect { get :show, { :params => { :id => '1' } } }.to_not raise_error
  end

  it 'should be able to map multiple powers to methods' do
    controller.stub :current_power => Power.new(:red => true, :blue => false)
    controller.send(:red_scope).should == 'red'
    controller.send(:blue_scope).should be_nil
    controller.stub :current_power => Power.new(:red => false, :blue => true)
    controller.send(:red_scope).should be_nil
    controller.send(:blue_scope).should == 'blue'
  end

  it 'should make a mapped power method private' do
    controller.stub :current_power => Power.new
    expect { controller.red_scope }.to raise_error(NoMethodError)
    expect { controller.send(:red_scope) }.to_not raise_error
  end

end
