class Client < ActiveRecord::Base

  has_many :notes

  named_scope :active, :conditions => ["deleted = ? OR deleted IS NULL", false]

end
