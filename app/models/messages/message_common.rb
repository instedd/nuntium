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
  
  def custom_attributes
    self[:custom_attributes] = {} if self[:custom_attributes].nil?
    self[:custom_attributes]
  end
  
  def country
    custom_attributes['country']
  end
  
  def country=(value)
    custom_attributes['country'] = value
  end
  
  def carrier
    custom_attributes['carrier']
  end
  
  def carrier=(value)
    custom_attributes['carrier'] = value
  end

  # Given an xml builder writes itself unto it
  def write_xml(xml)
    require 'builder'
    xml.message(:id => self.guid, :from => self.from, :to => self.to, :when => self.timestamp.xmlschema) do
      xml.text self.subject_and_body
      custom_attributes.each do |name, value|
        xml.property :name => name, :value => value
      end
    end
  end
  
  # Rule Engine related methods
  
  # Builds Context for AT Rules execution
  def rules_context
    return {
      :from => self.from,
      :to => self.to,
      :subject => self.subject,
      :body => self.body,
      :subject_and_body => self.subject_and_body }.merge(self.custom_attributes)
  end
  
  # merge attributes to current instance.
  # wellknown attributes are persisted in properties. Others as extensions
  def merge(attributes)
    attributes = attributes || {}
    
    self.from = attributes[:from] if attributes.has_key?(:from)
    self.to = attributes[:to] if attributes.has_key?(:to)
    self.subject = attributes[:subject] if attributes.has_key?(:subject)
    self.body = attributes[:body] if attributes.has_key?(:body)
    
    other_attributes = attributes.reject { |k,v| [:from,:to,:subject,:body].include?(k) }
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
  
    # Given an xml document string extracts all messages from it and yields them
    def parse_xml(txt_or_hash)
      tree = txt_or_hash.kind_of?(Hash) ? txt_or_hash : Hash.from_xml(txt_or_hash).with_indifferent_access
      
      messages = tree[:messages][:message]
      messages = [messages] if messages.class <= Hash 
      
      messages.each do |elem|
        msg = self.new
        msg.from = elem[:from]
        msg.to = elem[:to]
        msg.body = elem[:text]
        msg.guid = elem[:id]
        msg.timestamp = Time.parse(elem[:when])
        
        properties = elem[:property]
        if properties.present?
          properties = [properties] if properties.class <= Hash      
          properties.each do |prop|
            msg.custom_attributes[prop[:name]] = prop[:value]
          end
        end
        
        yield msg
      end
    end
    
  end
end
