class RisksController < ActionController::Base
  include Consul::Controller

  def _routes
    Rails.application.routes
  end

  def show
  end

end
