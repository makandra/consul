class CakesController < ApplicationController

  power :crud => :cakes, :as => :end_of_association_chain

  def show
    notify_spy
    render_nothing
  end

  def index
    notify_spy
    render_nothing
  end

  def new
    notify_spy
    render_nothing
  end

  def create
    notify_spy
    render_nothing
  end

  def edit
    notify_spy
    render_nothing
  end

  def update
    notify_spy
    render_nothing
  end

  def destroy
    notify_spy
    render_nothing
  end

  def custom_action
    notify_spy
    render_nothing
  end

  private

  def notify_spy
    observe_end_of_association_chain(end_of_association_chain)
  end

  def observe_end_of_association_chain(scope)
    # spy for spec
  end

end
