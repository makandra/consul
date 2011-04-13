require File.dirname(__FILE__) + '/../spec_helper'

describe SongsController do

  it "should raise an error if an action is not checked against a power" do
    expect { get :show, :id => '123' }.to raise_error(Consul::UncheckedPower)
  end

  it 'should allow to skip a required power check' do
    expect { get :index }.to_not raise_error
  end

end
