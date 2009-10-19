class CreateApplications < ActiveRecord::Migration
  def self.up
    create_table :applications do |t|
      t.string :name
      t.string :password

      t.timestamps
    end
  end

  def self.down
    drop_table :applications
  end
end
