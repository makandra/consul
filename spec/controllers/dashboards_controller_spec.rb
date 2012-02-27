require File.dirname(__FILE__) + '/../spec_helper'

describe DashboardsController do

  it "should not raise an error if the checked power is given" do
    expect { get :show }.to_not raise_error
  end

  it 'should define a method #current_power' do
    controller.private_methods.should include('current_power')
  end

  it "should set the current power before the request, and nilify it after the request" do
    controller.send(:current_power).should be_nil
    controller.should_receive(:observe).with(kind_of(Power))
    get :show
    controller.send(:current_power).should be_nil
  end

  it 'should nilify the current power even if the action raises an error' do
    expect { post :error }.to raise_error(/error during action/)
    controller.send(:current_power).should be_nil
  end

end
