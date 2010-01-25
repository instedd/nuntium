class ChangeConfigurationToTextInApplication < ActiveRecord::Migration
  def self.up
    change_column :applications, :configuration, :text
  end

  def self.down
    change_column :applications, :configuration, :string
  end
end
