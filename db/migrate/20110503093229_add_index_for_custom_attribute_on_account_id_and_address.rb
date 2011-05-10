class AddIndexForCustomAttributeOnAccountIdAndAddress < ActiveRecord::Migration
  def self.up
    add_index :custom_attributes, [:account_id, :address], :unique => true
  end

  def self.down
    remove_index :custom_attributes, :column => [:account_id, :address]
  end
end