class AddAddressToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :address, :string
  end

  def self.down
    remove_column :channels, :address
  end
end
