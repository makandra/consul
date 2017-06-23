class CreateClients < ConsulMigration

  def self.up
    create_table :clients do |t|
      t.boolean :deleted
    end
  end

  def self.down
    drop_table :clients
  end

end
