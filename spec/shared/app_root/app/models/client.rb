class Client < ActiveRecord::Base

  has_many :notes

  def self.active
    if Rails.version.to_i < 3
      scoped(:conditions => ["deleted = ? OR deleted IS NULL", false])
    else
      where("deleted = ? OR deleted IS NULL", false)
    end
  end

end
