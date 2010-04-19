class DropDrbProcesses < ActiveRecord::Migration
  def self.up
    drop_table :d_rb_processes
  end
  
  def self.down
    create_table :d_rb_processes do |t|
      t.references :application
      t.belongs_to :channel
      t.string :uri

      t.timestamps
    end
  end
end
