class CreateDRbProcesses < ActiveRecord::Migration
  def self.up
    create_table :d_rb_processes do |t|
      t.string :uri

      t.timestamps
    end
  end

  def self.down
    drop_table :d_rb_processes
  end
end
