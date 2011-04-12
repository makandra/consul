class Power
  include Consul::Power

  def initialize(user)
    @user = user
  end

  power :clients do
    Client.active
  end

  power :client_notes do |client|
    client.notes
  end

  power :admin do
    false
  end

  power :moderator do
    nil
  end
  
  power :dashboard do
    true
  end

end
