class ApplicationController < ActionController::Base
  include Consul::Controller

  require_power_check

  current_power do
    Power.new(User.new)
  end
  
end
