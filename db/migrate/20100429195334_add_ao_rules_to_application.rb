class AddAoRulesToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :ao_rules, :text
  end

  def self.down
    remove_column :applications, :ao_rules
  end
end
