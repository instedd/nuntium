class AddAoRulesToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :ao_rules, :text
  end

  def self.down
    remove_column :channels, :ao_rules
  end
end
