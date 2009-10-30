class RemoveSaltFromChannel < ActiveRecord::Migration
  def self.up
    remove_column :channels, :salt
  end

  def self.down
    add_column :channels, :salt, :string
  end
end
