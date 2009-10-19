class AddConfigurationToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :configuration, :string
  end

  def self.down
    remove_column :channels, :configuration
  end
end
