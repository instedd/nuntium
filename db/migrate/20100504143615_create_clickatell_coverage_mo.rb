class CreateClickatellCoverageMo < ActiveRecord::Migration
  def self.up
    create_table :clickatell_coverage_mos do |t|
      t.primary_key :id
      
      t.integer :country_id 
      t.integer :carrier_id 
      t.string :network 
      t.decimal :cost
      
      t.timestamps
    end
  end

  def self.down
    drop_table :clickatell_coverage_mos
  end
end
