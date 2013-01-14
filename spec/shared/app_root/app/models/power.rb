class Power
  include Consul::Power

  def initialize(user = nil)
    @user = user
  end

  power :clients do
    Client.active unless guest?
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

  power :cakes do
    :cakes
  end

  power :updatable_cakes do
    :updatable_cakes
  end

  power :creatable_cakes do
    :creatable_cakes
  end

  power :destroyable_cakes do
    :destroyable_cakes
  end

  def assignable_user_roles
    %w[guest admin]
  end

  power :key_figures do
    %w[amount working_costs] unless guest?
  end

  power :api_key do
    'secret-api-key' unless guest?
  end

  power :shorthand1, :shorthand2, :shorthand3 do
    'shorthand'
  end

  private

  attr_accessor :user

  def role
    user.role
  end

  def admin?
    user.role == 'admin'
  end

  def guest?
    user.role == 'guest'
  end

end
