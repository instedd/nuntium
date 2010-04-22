class AddCustomAttributesToAoMessages < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :custom_attributes, :text
  end

  def self.down
    remove_column :ao_messages, :custom_attributes
  end
end
