class AddSaltToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :salt, :string
  end

  def self.down
    remove_column :applications, :salt
  end
end
