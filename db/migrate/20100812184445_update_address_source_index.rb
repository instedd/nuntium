class UpdateAddressSourceIndex < ActiveRecord::Migration
  def self.up
    remove_index :address_sources, [:application_id, :address]
    add_index :address_sources, [:application_id, :address, :channel_id], :unique => true, :name => 'address_sources_idx'
  end

  def self.down
    remove_index :address_sources, :name => 'address_sources_idx'
    add_index :address_sources, [:application_id, :address], :unique => true
  end
end
