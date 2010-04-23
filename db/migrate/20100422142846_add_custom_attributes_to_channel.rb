class AddCustomAttributesToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :custom_attributes, :text
  end

  def self.down
    remove_column :channels, :custom_attributes
  end
end
