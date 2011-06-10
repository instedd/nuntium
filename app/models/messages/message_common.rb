require 'guid'

module MessageCommon

  Fields = ['from', 'to', 'subject', 'body', 'guid']

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

  def from=(value)
    value = "sms://#{value.mobile_number}" if value && value.protocol == 'sms'
    super value
  end

  def to=(value)
    value = "sms://#{value.mobile_number}" if value && value.protocol == 'sms'
    super value
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
  custom_attributes_accessor :cost

  # Optimizations can be:
  #  - :mobile_number => associated to the message, so that it does not need to
  #                      be read when completing missing fields
  def infer_custom_attributes(optimizations = {})
    address = self.kind_of?(AOMessage) ? to : from
    return if not address or address.protocol != 'sms'

    number = address.mobile_number

    # Infer country from phone number
    if not self.country
      countries = Country.all.select{|x| number.start_with? x.phone_prefix}
      if countries.length > 0
        # Slipt countries with and without area codes
        with_area_codes, without_area_codes = countries.partition{|x| x.area_codes.present?}
        # From those with area codes, select only the ones for which the number start with them
        with_area_codes = with_area_codes.select{|x| x.area_codes.split(',').any?{|y| number.start_with?(x.phone_prefix + y.strip)}}
        # If we find matches with area codes, use them. Otherwise, use those without area codes
        countries = with_area_codes.present? ? with_area_codes : without_area_codes

        if countries.length == 1
          ThreadLocalLogger << "Country #{countries[0].name} (#{countries[0].iso2}) was inferred from prefix"
          self.country = countries[0].iso2
        else
          self.country = countries.map do |c|
            ThreadLocalLogger << "Country #{c.name} (#{c.iso2}) was inferred from prefix"
            c.iso2
          end
        end
      end
    end

    # Infer carrier from phone number (if country is present)
    if self.country and not self.carrier
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
          if prefixes.any?{|p| number.start_with?(c.phone_prefix + p.strip)}
            ThreadLocalLogger << "Carrier #{carrier.name} was inferred from prefix"
            carriers << carrier
          end
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

    # Infer country and carrier from stored MobileNumber, if any
    mob = optimizations[:mobile_number] || (MobileNumber.find_by_number number)
    mob.complete_missing_fields self if mob
  end

  # Given an xml builder writes itself unto it
  def write_xml(xml)
    require 'builder'
    options = {:id => self.guid, :from => self.from, :to => self.to}
    options[:when] = self.timestamp.xmlschema if self.timestamp
    xml.message(options) do
      xml.text self.subject_and_body
      custom_attributes.each_multivalue do |name, values|
        values.each { |value| xml.property :name => name, :value => value }
      end
      xml.property :name => 'token', :value => self.token if self.token
    end
  end

  def to_qst
    h = {'id' => guid, 'from' => from, 'to' => to, 'text' => subject_and_body, 'when' => timestamp}
    h['properties'] = custom_attributes if custom_attributes.present?
    h
  end

  def to_json(options = {})
    hash = {}
    Fields.each do |field|
      value = send field
      hash[field] = value if value
    end
    hash['channel'] = channel.try(:name)
    hash['channel_kind'] = channel.try(:kind)
    hash['state'] = state
    hash.merge!(custom_attributes)
    hash.to_json
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

    original = {}

    Fields.each do |sym|
      if attributes.has_key? sym
        old = send sym
        send "#{sym}=", attributes[sym]
        original[sym] = old unless original[sym]
        ThreadLocalLogger << "'#{sym}' changed from '#{old}' to '#{attributes[sym]}'"
      end
    end

    other_attributes = attributes.reject { |k,v| Fields.include?(k) }
    other_attributes.each do |key, value|
      if key == 'cancel'
        self.state = 'canceled'
      else
        old = custom_attributes[key]
        custom_attributes[key] = value
        original[key] = old unless original[key]
        ThreadLocalLogger << "'#{key}' changed from '#{old}' to '#{value}'"
      end
    end

    original.present? ? original : nil
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
      msgs.map do |x|
        m = self.new :guid => x['id'], :from => x['from'], :to => x['to'], :body => x['text'], :timestamp => x['when']
        m.custom_attributes = x['properties'] if x['properties'].present?
        m
      end
    end

    # Given an xml document string extracts all messages from it and yields them
    def parse_xml(txt_or_hash)
      tree = txt_or_hash.kind_of?(Hash) ? txt_or_hash : Hash.from_xml(txt_or_hash).with_indifferent_access

      messages = ((tree || {})[:messages] || {})[:message]
      messages = [messages] if messages.class <= Hash

      (messages || []).each do |elem|
        next if elem.kind_of? String

        msg = self.new
        msg.from = elem[:from]
        msg.to = elem[:to]
        msg.body = elem[:text]
        msg.guid = elem[:id] if elem[:id].present?
        msg.timestamp = Time.parse(elem[:when]) if elem[:when] rescue nil

        properties = elem[:property]
        if properties.present?
          properties = [properties] if properties.class <= Hash
          properties.each do |prop|
            if prop[:name] == 'token'
              msg.token = prop[:value]
            else
              msg.custom_attributes.store_multivalue prop[:name], prop[:value]
            end
          end
        end

        yield msg
      end
    end

    def from_json(data)
      data = JSON.parse(data) if data.is_a? String
      data = [data] unless data.is_a? Array
      data.each do |hash|
        msg = from_hash hash
        yield msg
      end
    end

    def from_hash(hash)
      hash = hash.with_indifferent_access

      msg = self.new
      hash.each do |key, value|
        if [:from, :to, :subject, :body, :guid, :token].include? key.to_sym
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
