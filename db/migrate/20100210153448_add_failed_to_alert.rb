class AddFailedToAlert < ActiveRecord::Migration
  def self.up
    add_column :alerts, :failed, :boolean, :default => 0
  end

  def self.down
    remove_column :alerts, :failed
  end
end
