class SongsController < ApplicationController

  # power check is missing

  skip_power_check :only => :index

  def show
  end

  def index
  end

end
