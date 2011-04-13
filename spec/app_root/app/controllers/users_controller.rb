class UsersController < ApplicationController

  power :admin, :map => { :index => :dashboard }

  def index
  end

  def show
  end

end
