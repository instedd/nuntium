class CreateUserApplications < ActiveRecord::Migration
  def self.up
    create_table :user_applications do |t|
      t.integer :user_id
      t.integer :application_id
      t.string :role

      t.timestamps
    end
  end

  def self.down
    drop_table :user_applications
  end
end
