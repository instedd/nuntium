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
        self.subject + ' - ' + self.body
      end
    end
  end

  # Given an xml builder writes itself unto it
  def write_xml(xml)
    require 'builder'
    xml.message(:id => self.guid, :from => self.from, :to => self.to, :when => self.timestamp.xmlschema) do
      xml.text self.subject_and_body
    end
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
    def parse_xml(xml_txt)
      require 'rexml/document'
  
      msgs = []
      doc = REXML::Document.new(xml_txt)
      doc.elements.each 'messages/message' do |elem|
        msg = self.new
        msg.from = elem.attributes['from']
        msg.to = elem.attributes['to']
        msg.body = elem.elements['text'].text
        msg.guid = elem.attributes['id']
        msg.timestamp = Time.parse(elem.attributes['when'])
        if block_given? then yield msg else msgs << msg end  
      end
      msgs
    end
    
  end
end

# TODO: This should not be here...
class String
  # Returns this string's protocol or '' if it doesn't have one.
  #   'sms://foobar'.protocol => 'sms'
  #   'foobar'.protocol => ''
  def protocol
    i = self.index '://'
    i.nil? ? '' : self[0 ... i]
  end
  
  # Returns this string without the protocol part.
  #   'sms://foobar'.without_protocol => 'foobar'
  #   'foobar'.without_protocol => 'foobar'
  def without_protocol
    i = self.index '://'
    i.nil? ? self : self[i + 3 ... self.length]
  end
  
  def with_protocol(protocol)
    i = self.index '://'
    if i.nil?
      protocol.to_s + '://' + self
    elsif self.protocol != protocol
      protocol.to_s + '://' + self.without_protocol
    else
      self
    end
  end
  
  def starts_with?(str)
    self[0...str.length] == str
  end
  
  def integer?
    Integer(self) rescue nil
  end
  
end