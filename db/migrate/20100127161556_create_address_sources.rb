class CreateAddressSources < ActiveRecord::Migration
  def self.up
    create_table :address_sources do |t|
      t.primary_key :id
      t.integer :application_id
      t.string :address
      t.integer :channel_id
      t.timestamp :timestamp

      t.timestamps
    end
    
    add_index :address_sources, [:application_id, :address], :unique => true
  end

  def self.down
    remove_index :address_sources, [:application_id, :address]
    drop_table :address_sources
  end
end
