class Client < ActiveRecord::Base

  has_many :notes

  def self.active
    scoped(:conditions => ["deleted = ? OR deleted IS NULL", false])
  end

end
