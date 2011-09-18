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

  power :notes do
    Note.scoped(:joins => :client)
  end

  power :always_true do
    true
  end

  power :always_false do
    false
  end

  power :always_nil do
    nil
  end

end
