class Song < ActiveRecord::Base

  default_scope :conditions => { :trashed => true }

  Consul::Util.define_scope(self, :recent, :conditions  => ['created_at > ?', 1.week.ago])

end
