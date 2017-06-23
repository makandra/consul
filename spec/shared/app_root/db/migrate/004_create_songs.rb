class CreateSongs < ConsulMigration

  def self.up
    create_table :songs do |t|
      t.boolean :trashed
      t.timestamps
    end
  end

  def self.down
    drop_table :songs
  end

end
