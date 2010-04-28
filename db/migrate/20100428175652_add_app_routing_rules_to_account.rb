class AddAppRoutingRulesToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :app_routing_rules, :text
  end

  def self.down
    remove_column :accounts, :app_routing_rules
  end
end
