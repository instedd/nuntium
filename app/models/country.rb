class Country < ActiveRecord::Base
  has_many :carriers
  
  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.country :name => name, :iso2 => iso2, :iso3 => iso3, :phone_prefix => phone_prefix
  end
end
