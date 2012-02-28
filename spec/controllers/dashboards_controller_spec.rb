require File.dirname(__FILE__) + '/../spec_helper'

describe DashboardsController do

  it "should not raise an error if the checked power is given" do
    expect { get :show }.to_not raise_error
  end

  it 'should define a method #current_power that returns the Power' do
    controller.should_receive(:observe).with(kind_of(Power))
    get :show
  end

  it "should set the current power before the request, and nilify it after the request" do
    controller.send(:current_power).should be_nil
    Power.should_receive_and_execute(:current=).ordered.with(kind_of(Power))
    Power.should_receive_and_execute(:current=).ordered.with(nil)
    get :show
  end

  it 'should nilify the current power even if the action raises an error' do
    expect { post :error }.to raise_error(/error during action/)
    Power.current.should be_nil
  end

end
