require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do

  it "should raise an error if the checked power is not given" do
    expect { get :show, :id => '1' }.to raise_error(Consul::Powerless)
  end

  it 'should allow to map actions to another power' do
    expect { get :index }.to_not raise_error
  end

end
