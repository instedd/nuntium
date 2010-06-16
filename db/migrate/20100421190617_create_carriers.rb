class CreateCarriers < ActiveRecord::Migration
  def self.up
    create_table :carriers do |t|
      t.integer :country_id
      t.string :name
      t.string :clickatell_name
      t.string :guid
      t.string :prefixes

      t.timestamps
    end
  end

  def self.down
    drop_table :carriers
  end
end
