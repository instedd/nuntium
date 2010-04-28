class ChangeAtRulesToText < ActiveRecord::Migration
  def self.up
    change_column :channels, :at_rules, :text
  end

  def self.down
  end
end
