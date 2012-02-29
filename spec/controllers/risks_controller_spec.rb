require File.dirname(__FILE__) + '/../spec_helper'

describe RisksController do

  it "should raise an error it includes Consul::Controller but forgets to define current_power do ... end" do
    expect { put :show, :id => '1' }.to raise_error(Consul::UnreachablePower)
  end

end
