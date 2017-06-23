class CreateNotes < ConsulMigration

  def self.up
    create_table :notes do |t|
      t.integer :client_id
    end
  end

  def self.down
    drop_table :notes
  end

end
