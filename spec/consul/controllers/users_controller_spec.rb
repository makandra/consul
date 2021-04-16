require 'spec_helper'

describe UsersController, :type => :controller do

  it "should raise an error if the checked power is not given" do
    expect { get :update, :params => { :id => '1' } }.to raise_error(Consul::Powerless)
  end

  it 'should allow to map actions to another power using the :map option' do
    expect { get :show, :params => { :id => '1' } }.to_not raise_error
  end


  #describe '.power_name_for_action' do
  #
  #  it 'should return the name of the power for the given action (feature request from devolute)' do
  #    UsersController.power_name_for_action(:show).should == :always_true
  #    UsersController.power_name_for_action('show').should == :always_true
  #    UsersController.power_name_for_action(:update).should == :always_false
  #    UsersController.power_name_for_action('update').should == :always_false
  #  end
  #
  #end

end
