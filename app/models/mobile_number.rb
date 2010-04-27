class MobileNumber < ActiveRecord::Base
  belongs_to :country
  belongs_to :carrier
  
  def self.update(number, country, carrier)
    country = Country.find_by_iso2_or_iso3 country if country
    carrier = Carrier.find_by_guid carrier if carrier
    if country or carrier
      mob = MobileNumber.find_by_number number
      mob = MobileNumber.new(:number => number) if mob.nil?
      mob.country_id = country.id if country
      mob.carrier_id = carrier.id if carrier
      mob.save!
    end
  end
end
