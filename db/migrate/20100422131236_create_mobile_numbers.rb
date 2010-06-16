class CreateMobileNumbers < ActiveRecord::Migration
  def self.up
    create_table :mobile_numbers do |t|
      t.string :number
      t.integer :country_id
      t.integer :carrier_id

      t.timestamps
    end
  end

  def self.down
    drop_table :mobile_numbers
  end
end
