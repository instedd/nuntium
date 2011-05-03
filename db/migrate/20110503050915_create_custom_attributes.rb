class CreateCustomAttributes < ActiveRecord::Migration
  def self.up
    create_table :custom_attributes do |t|
      t.integer :account_id
      t.string :address
      t.text :custom_attributes

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_attributes
  end
end
