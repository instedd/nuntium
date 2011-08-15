class Carrier < ActiveRecord::Base
  belongs_to :country
  has_many :mobile_numbers

  before_destroy :clear_cache
  after_save :clear_cache

  @@carriers = nil

  def self.all
    return @@carriers if @@carriers

    @@carriers = super
    @@carriers.sort!{|x, y| x.name <=> y.name}
    @@carriers
  end

  def self.all_with_countries
    countries = Country.all.inject({}) { |memo, obj| memo[obj.id] = obj; memo }

    carriers = all
    carriers.each {|c| c.country = countries[c.country_id]}
    carriers
  end

  def self.find_by_id(id)
    all.select{|c| c.id == id}.first
  end

  def self.find_by_country_id(country_id)
    all.select {|x| x.country_id == country_id}
  end

  def self.find_by_guid(guid)
    all.select {|x| x.guid == guid}.first
  end

  def self.find_by_name(name)
    all.select {|x| x.name == name}.first
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.carrier :name => name, :guid => guid, :country_iso2 => country.iso2
  end

  def as_json(options = {})
    {:name => name, :guid => guid, :country_iso2 => country.iso2}
  end

  def self.clear_cache
    @@carriers = nil
  end

  private

  def clear_cache
    @@carriers = nil
  end
end
