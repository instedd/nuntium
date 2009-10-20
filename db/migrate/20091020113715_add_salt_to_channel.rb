class AddSaltToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :salt, :string
  end

  def self.down
    remove_column :channels, :salt
  end
end
