class Country < ActiveRecord::Base
  has_many :carriers
  has_many :mobile_numbers
  
  before_destroy :clear_cache 
  after_save :clear_cache
  
  def self.all
    countries = Rails.cache.read 'countries'
    if not countries
      countries = super
      countries.sort!{|x, y| x.name <=> y.name}
      Rails.cache.write 'countries', countries
    end
    countries
  end
  
  def self.find_by_id(id, countries = all)
    countries.select{|c| c.id == id}.first
  end
  
  def self.find_by_iso2(iso2)
    all.select{|c| c.iso2.casecmp(iso2) == 0}.first
  end
  
  def self.find_by_iso3(iso3)
    all.select{|c| c.iso3.casecmp(iso3) == 0}.first
  end
  
  def self.find_by_iso2_or_iso3(iso)
    all.select{|c| c.iso2.casecmp(iso) == 0 || c.iso3.casecmp(iso) == 0}.first
  end
  
  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.country :name => name, :iso2 => iso2, :iso3 => iso3, :phone_prefix => phone_prefix
  end
  
  private
  
  def clear_cache
    Rails.cache.delete 'countries'
  end
end
