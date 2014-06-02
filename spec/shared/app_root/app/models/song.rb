class Song < ActiveRecord::Base

  if Rails.version.to_i < 3
    default_scope :conditions => { :trashed => true }
    Consul::Util.define_scope(self, :recent, :conditions  => ['created_at > ?', 1.week.ago])
  else
    default_scope lambda { where(:trashed => true) }
    Consul::Util.define_scope(self, :recent, where('created_at > ?', 1.week.ago))
  end

end
