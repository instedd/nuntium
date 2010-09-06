class ChangeCostColumnToDecimalInClickatellCoverageMo < ActiveRecord::Migration
  def self.up
    change_column :clickatell_coverage_mos, :cost, :decimal, :limit => 10, :precision => 10, :scale => 2
  end

  def self.down
    change_column :clickatell_coverage_mos, :cost, :integer
  end
end
