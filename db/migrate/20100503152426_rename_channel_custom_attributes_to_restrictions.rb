class RenameChannelCustomAttributesToRestrictions < ActiveRecord::Migration
  def self.up
    rename_column :channels, :custom_attributes, :restrictions
  end

  def self.down
    rename_column :channels, :restrictions, :custom_attributes
  end
end
