class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
      t.string :name
      t.string :iso2, :limit => 2
      t.string :iso3, :limit => 3
      t.string :phone_prefix

      t.timestamps
    end
  end

  def self.down
    drop_table :countries
  end
end
