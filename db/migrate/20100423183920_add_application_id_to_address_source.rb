class AddApplicationIdToAddressSource < ActiveRecord::Migration
  def self.up
    add_column :address_sources, :application_id, :integer
  end

  def self.down
    remove_column :address_sources, :application_id
  end
end
