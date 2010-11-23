class AddAreaCodesToCountry < ActiveRecord::Migration
  def self.up
    add_column :countries, :area_codes, :text
  end

  def self.down
    remove_column :countries, :area_codes
  end
end
