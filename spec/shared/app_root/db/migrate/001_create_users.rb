class CreateUsers < ConsulMigration

  def self.up
    create_table :users do |t|
      t.string :role
    end
  end

  def self.down
    drop_table :users
  end

end
