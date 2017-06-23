class ApplicationController < ActionController::Base
  include Consul::Controller

  require_power_check

  current_power do
    Power.new(User.new)
  end

  private

  def render_nothing
    if Rails.version.to_i < 5
      render :nothing => true
    else
      render :body => ''
    end
  end
  
end
