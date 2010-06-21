require 'guid'

module MessageCommon

  def self.included(base)
    base.extend(ClassMethods)
    base.before_save :generate_guid
  end
  
  def generate_guid
    self.guid ||= Guid.new.to_s
  end
  
  # Returns the subject and body of this message concatenated
  # with a dash, or either of them if the other is empty.
  def subject_and_body
    if self.subject.nil? || self.subject == ''
      if self.body.nil? || self.body == ''
        ''
      else
        self.body
      end
    else
      if self.body.nil? || self.body == ''
        self.subject
      else
        "#{self.subject} - #{self.body}"
      end
    end
  end
  
  # A Hash where each value can be a string or an Array of strings
  def custom_attributes
    self[:custom_attributes] = {} if self[:custom_attributes].nil?
    self[:custom_attributes]
  end
  
  def self.custom_attributes_accessor(name, default = nil)
    define_method(name) do
      custom_attributes[name.to_s] || default
    end
    define_method("#{name}=") do |value|
      custom_attributes[name.to_s] = value
    end
  end
  
  custom_attributes_accessor :country
  custom_attributes_accessor :carrier
  custom_attributes_accessor :strategy
  custom_attributes_accessor :suggested_channel
  
  def infer_custom_attributes
    unless country
      address = self.kind_of?(AOMessage) ? to : from
      return if not address or address.protocol != 'sms'
      
      number = address.mobile_number
      countries = Country.all.select{|x| number.start_with? x.phone_prefix}
      return if countries.empty?
      
      if countries.length == 1
        self.country = countries[0].iso2
      else
        self.country = countries.map &:iso2
      end
    end
    
    return unless self.country
    return if self.carrier
    
    countries = self.country
    countries = [countries] unless countries.kind_of? Array
    countries = countries.map{|x| Country.find_by_iso2_or_iso3 x}
    
    carriers = []
    
    countries.each do |c|
      next unless c
      cs = Carrier.find_by_country_id c.id
      cs.each do |carrier| 
        next unless carrier.prefixes.present?
        prefixes = carrier.prefixes.split ','
        carriers << carrier if prefixes.any?{|p| number.start_with?(c.phone_prefix + p.strip)}
      end
    end
    
    unless carriers.empty?
      if carriers.length == 1
        self.carrier = carriers[0].guid
      else
        self.carrier = carriers.map &:guid
      end
    end
  end

  # Given an xml builder writes itself unto it
  def write_xml(xml)
    require 'builder'
    xml.message(:id => self.guid, :from => self.from, :to => self.to, :when => self.timestamp.xmlschema) do
      xml.text self.subject_and_body
      custom_attributes.each_multivalue do |name, values|
        values.each do |value|
          xml.property :name => name, :value => value
        end
      end
    end
  end
  
  def to_qst
    {'id' => guid, 'from' => from, 'to' => to, 'text' => subject_and_body, 'when' => timestamp}
  end
  
  # Rule Engine related methods
  
  # Builds Context for AT Rules execution
  def rules_context
    return {
      "from" => self.from,
      "to" => self.to,
      "subject" => self.subject,
      "body" => self.body,
      "subject_and_body" => self.subject_and_body }.merge(self.custom_attributes)
  end
  
  # merge attributes to current instance.
  # wellknown attributes are persisted in properties. Others as extensions
  def merge(attributes)
    attributes = attributes || {}
    
    ['from', 'to', 'subject', 'body'].each do |sym|
      send "#{sym}=", attributes[sym] if attributes.has_key? sym
    end
    
    other_attributes = attributes.reject { |k,v| ["from","to","subject","body"].include?(k) }
    self[:custom_attributes] = self.custom_attributes.merge(other_attributes)
  end

  module ClassMethods
    # Given a collection of messages serializes them to a single document
    def write_xml(msgs)
      require 'builder'
      xml = Builder::XmlMarkup.new(:indent => 1)
      xml.instruct!
      xml.messages do
        msgs.each do |msg|
          msg.write_xml xml
        end
      end
      xml.target!
    end
    
    def to_qst(msgs)
      msgs.map{|x| x.to_qst}
    end
    
    def from_qst(msgs)
      msgs.map{|x| self.new :guid => x['id'], :from => x['from'], :to => x['to'], :body => x['text'], :timestamp => x['when']}
    end
  
    # Given an xml document string extracts all messages from it and yields them
    def parse_xml(txt_or_hash)
      tree = txt_or_hash.kind_of?(Hash) ? txt_or_hash : Hash.from_xml(txt_or_hash).with_indifferent_access
      
      messages = ((tree || {})[:messages] || {})[:message]
      messages = [messages] if messages.class <= Hash 
      
      (messages || []).each do |elem|
        msg = self.new
        msg.from = elem[:from]
        msg.to = elem[:to]
        msg.body = elem[:text]
        msg.guid = elem[:id]
        msg.timestamp = Time.parse(elem[:when]) if elem[:when] rescue nil
        
        properties = elem[:property]
        if properties.present?
          properties = [properties] if properties.class <= Hash      
          properties.each do |prop|
            msg.custom_attributes.store_multivalue prop[:name], prop[:value]
          end
        end
        
        yield msg
      end
    end
    
    def from_hash(hash)
      msg = self.new
      hash.each do |key, value|
        if [:from, :to, :subject, :body, :guid].include? key.to_sym
          # Normal attribute
          msg.send "#{key}=", value
        elsif [:controller, :action, :application_name, :account_name].include? key.to_sym
          # Nothing, ignore these because they come from the request
        else
          # Custom attribute
          msg.custom_attributes[key] = value
        end
      end
      msg
    end
    
  end
end
