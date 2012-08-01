class DashboardsController < ApplicationController
  
  power :always_true

  def show
    observe(current_power)
  end

  def error
    raise 'error during action'
  end

  private

  def observe(object)
    # test spy
  end

end
