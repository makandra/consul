require File.dirname(__FILE__) + '/../spec_helper'

describe DashboardsController do

  it "should not raise an error if the checked power is given" do
    expect { get :show }.to_not raise_error
  end

end
