class AddClickatellNameToCountry < ActiveRecord::Migration
  def self.up
    add_column :countries, :clickatell_name, :string
  end

  def self.down
    remove_column :countries, :clickatell_name
  end
end
