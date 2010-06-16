class AddApplicationIdToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :application_id, :integer
  end

  def self.down
    remove_column :channels, :application_id
  end
end
