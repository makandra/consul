require 'spec_helper'

describe RisksController, :type => :controller do

  it "should raise an error it includes Consul::Controller but forgets to define current_power do ... end" do
    expect { put :show, wrap_params(:id => '1') }.to raise_error(Consul::UnreachablePower)
  end

end
