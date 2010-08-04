class AddApplicationIdToAccountLog < ActiveRecord::Migration
  def self.up
    add_column :account_logs, :application_id, :integer
  end

  def self.down
    remove_column :account_logs, :application_id
  end
end
