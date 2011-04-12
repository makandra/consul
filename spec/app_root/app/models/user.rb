class User < ActiveRecord::Base

  def power
    @power ||= Power.new(self)
  end

end

