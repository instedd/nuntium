class AddMaxTriesToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :max_tries, :int, :default => 3, :null => false
  end

  def self.down
    remove_column :applications, :max_tries
  end
end
