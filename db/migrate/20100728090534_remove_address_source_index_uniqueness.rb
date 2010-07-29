class RemoveAddressSourceIndexUniqueness < ActiveRecord::Migration
  def self.up
    remove_index :address_sources, [:application_id, :address]
    add_index :address_sources, [:application_id, :address]
  end

  def self.down
    remove_index :address_sources, [:application_id, :address]
    add_index :address_sources, [:application_id, :address], :unique => true
  end
end
