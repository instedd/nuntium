class Country < ActiveRecord::Base
  has_many :carriers
  has_many :mobile_numbers
  
  def self.all
    countries = Rails.cache.read 'countries'
    if not countries
      countries = super
      countries.sort!{|x, y| x.name <=> y.name}
      Rails.cache.write 'countries', countries
    end
    countries
  end
  
  def self.find_by_iso2(iso2)
    all.select{|c| c.iso2 == iso2}.first
  end
  
  def self.find_by_iso3(iso3)
    all.select{|c| c.iso3 == iso3}.first
  end
  
  def self.find_by_iso2_or_iso3(iso)
    all.select{|c| c.iso2 == iso || c.iso3 == iso}.first
  end
  
  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.country :name => name, :iso2 => iso2, :iso3 => iso3, :phone_prefix => phone_prefix
  end
end
