class Country < ActiveRecord::Base
  has_many :carriers
  has_many :mobile_numbers
  
  before_destroy :clear_cache 
  after_save :clear_cache
  
  @@countries = nil
  
  def self.all
    return @@countries if @@countries
    
    @@countries = super
    @@countries.sort!{|x, y| x.name <=> y.name}
    @@countries
  end
  
  def self.find_by_id(id)
    all.select{|c| c.id == id}.first
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
  
  def self.clear_cache
    @@countries = nil
  end
  
  private
  
  def clear_cache
    @@countries = nil
  end
end
