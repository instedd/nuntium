class AddCustomAttributesToAtMessages < ActiveRecord::Migration
  def self.up
    add_column :at_messages, :custom_attributes, :text
  end

  def self.down
    remove_column :at_messages, :custom_attributes
  end
end
