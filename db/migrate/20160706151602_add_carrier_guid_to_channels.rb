class AddCarrierGuidToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :carrier_guid, :string
  end
end
