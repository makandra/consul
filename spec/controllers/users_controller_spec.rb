require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do

  it "should raise an error if the checked power is not given" do
    expect { get :update, :id => '1' }.to raise_error(Consul::Powerless)
  end

  it 'should allow to map actions to another power using the :map option' do
    expect { get :show, :id => '1' }.to_not raise_error
  end

end
