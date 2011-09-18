class UsersController < ApplicationController

  power :always_false, :map => { :show => :always_true }

  def show
  end

  def update
  end

end
