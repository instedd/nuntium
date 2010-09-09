class AddAtRulesToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :at_rules, :text
  end

  def self.down
    remove_column :applications, :at_rules
  end
end
