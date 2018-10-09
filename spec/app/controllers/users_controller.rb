class UsersController < ApplicationController

  power :always_false, :map => { :show => :always_true }

  def show
    render_nothing
  end

  def update
    render_nothing
  end

end
