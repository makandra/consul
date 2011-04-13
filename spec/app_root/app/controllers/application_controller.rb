class ApplicationController < ActionController::Base
  include Consul::Controller

  require_power_check

  private

  def current_power
    Power.new User.new
  end
  
end
