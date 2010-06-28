class MobileNumber < ActiveRecord::Base
  belongs_to :country
  belongs_to :carrier
  
  def country
    country_id ? (Country.find_by_id country_id) : nil
  end
  
  def carrier
    carrier_id ? (Carrier.find_by_id carrier_id) : nil
  end
  
  def self.update(number, country, carrier)
    if country and not country.kind_of? Array
      country = Country.find_by_iso2_or_iso3 country if country
    else
      country = nil
    end
    if carrier and not carrier.kind_of? Array
      carrier = Carrier.find_by_guid carrier if carrier
    else
      carrier = nil
    end
    if country or carrier
      mob = MobileNumber.find_by_number number
      mob = MobileNumber.new(:number => number) if mob.nil?
      mob.country_id = country.id if country
      mob.carrier_id = carrier.id if carrier
      mob.save!
    end
  end
  
  def self.complete_missing_fields(msg)
    mob = MobileNumber.find_by_number msg.to.mobile_number
    mob.complete_missing_fields msg if mob
  end
  
  def complete_missing_fields(msg)
    # complete country
    msg.country = country.iso2 if not msg.country and country
    # complete carrier
    msg.carrier = carrier.guid if not msg.carrier and carrier
  end
end
