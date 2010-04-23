class AddAtRulesToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :at_rules, :string
  end

  def self.down
    remove_column :channels, :at_rules
  end
end
