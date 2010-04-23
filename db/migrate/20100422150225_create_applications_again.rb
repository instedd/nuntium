class CreateApplicationsAgain < ActiveRecord::Migration
  def self.up
    create_table :applications do |t|
      t.string :name
      t.integer :account_id
      t.string :interface
      t.text :configuration

      t.timestamps
    end
  end

  def self.down
    drop_table :applications
  end
end
