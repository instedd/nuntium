class AddPasswordAndSaltToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :password, :string
    add_column :applications, :salt, :string
  end

  def self.down
    remove_column :applications, :salt
    remove_column :applications, :password
  end
end
