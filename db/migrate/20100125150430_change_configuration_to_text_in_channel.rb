class ChangeConfigurationToTextInChannel < ActiveRecord::Migration
  def self.up
    change_column :channels, :configuration, :text
  end

  def self.down
    change_column :channels, :configuration, :string
  end
end
