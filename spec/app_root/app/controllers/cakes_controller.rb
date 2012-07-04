class CakesController < ApplicationController

  power :crud => :cakes, :as => :end_of_association_chain

  def show
    notify_spy
  end

  def index
    notify_spy
  end

  def new
    notify_spy
  end

  def create
    notify_spy
  end

  def edit
    notify_spy
  end

  def update
    notify_spy
  end

  def destroy
    notify_spy
  end

  def custom_action
    notify_spy
  end

  private

  def notify_spy
    observe_end_of_association_chain(end_of_association_chain)
  end

  def observe_end_of_association_chain(scope)
    # spy for spec
  end

end
