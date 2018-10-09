class ColorsController < ApplicationController

  power :red, :as => :red_scope
  power :blue, :as => :blue_scope

  def show
    render_nothing
  end

end