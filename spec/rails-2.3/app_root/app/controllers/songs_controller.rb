class SongsController < ApplicationController

  # power check is missing, but we're skipping it for a single action'
  skip_power_check :only => :show

  def show
  end

  def update
  end

end
