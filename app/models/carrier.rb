class Carrier < ActiveRecord::Base
  belongs_to :country
  
  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.carrier :name => name, :guid => guid, :country_iso2 => country.iso2
  end
  
  def to_json(options = {})
    "{\"name\":\"#{escape(name)}\",\"guid\":\"#{escape(guid)}\",\"country_iso2\":\"#{escape(country.iso2)}\"}"
  end
  
  private
  
  def escape(str)
    str.gsub('"', '\\\\"')
  end
end
