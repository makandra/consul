class Song < ActiveRecord::Base

  Consul::Util.define_default_scope self, :conditions => { :trashed => true }
  Consul::Util.define_scope self, :recent, lambda { { :conditions => ['created_at > ?', 1.week.ago] } }

end
