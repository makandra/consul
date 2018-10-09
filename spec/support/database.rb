database = Gemika::Database.new
database.connect
database.rewrite_schema! do

  create_table :users do |t|
    t.string :role
  end

  create_table :clients do |t|
    t.boolean :deleted
  end

  create_table :notes do |t|
    t.integer :client_id
  end

  create_table :songs do |t|
    t.boolean :trashed
    t.timestamps :null => false
  end

end
