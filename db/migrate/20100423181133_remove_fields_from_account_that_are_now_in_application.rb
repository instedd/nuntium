class RemoveFieldsFromAccountThatAreNowInApplication < ActiveRecord::Migration
  def self.up
    remove_column :accounts, :interface
    remove_column :accounts, :configuration
  end

  def self.down
    add_column :accounts, :interface, :string, :default => 'rss'
    add_column :accounts, :configuration, :string
  end
end
