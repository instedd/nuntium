class ATMessage < ActiveRecord::Base
  belongs_to :application
  validates_presence_of :application

  # Given an xml builder writes itself unto it
  def write_xml(xml)
    require 'builder'
    xml.message(:id => self.guid, :from => self.from, :to => self.to, :when => self.timestamp.xmlschema) do
      xml.text self.subject_and_body
    end
  end

  # Given an xml document string extracts all messages from it and yields them
  def self.parse_xml(xml_txt)
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

  # Marks all older messages as confirmed
  # * if msg_or_id does not correspond to a valid message, no action is executed
  # * returns the message corresponding to msg_or_id if exists
  def self.mark_older_as_confirmed(app_id, msg_or_id)
    msg = self.get_message(msg_or_id)
    if msg
      self.update_all("state = 'confirmed'", ["application_id = ? AND state IN ('delivered', 'queued') AND timestamp < ?", app_id, msg.timestamp])
      return msg
    end
  end
  
  # Returns all messages for an application newer than a specific message
  # * all app's messages are returned if msg_or_id is nil
  def self.fetch_app_newer_messages(app_id, msg_or_id, desc=false, batch_size=10)
    msg = self.get_message(msg_or_id)
    
    query = 'application_id = ? AND (state = ? OR state = ?)'
    params = [app_id, 'queued', 'delivered']
    
    # Filter by date if requested
    if msg
      query += ' AND timestamp > ?'
      params.push msg.timestamp
    end
    
    # Order by time, last arrived message will be first
    return self.all(
      :order => 'timestamp ' + (desc ? 'DESC' : 'ASC'), 
      :conditions => [query] + params,
      :limit => batch_size)
    
  end
  
  # Given a list of messages and the maximum retries count, updates their status
  # * if the processing was successful, messages are marked as delivered
  # * if it failed, they are marked as failed if they exceeded max tries
  # * in either case, retries count is increased 
  def self.update_msgs_status(msgs, max_tries, success=true)
    if success
      msgs_ids = msgs.map {|m| m.id}
      self.update_all("state = 'delivered', tries = tries + 1", ['id IN (?)', msgs_ids])
    else
      valid_msgs_ids, invalid_msgs_ids = msgs.partition {|m| m.tries < max_tries}.map {|ms| ms.map {|m| m.id}}
      self.update_all("tries = tries + 1", ['id IN (?)', valid_msgs_ids])
      self.update_all("state = 'failed', tries = tries + 1", ['id IN (?)', invalid_msgs_ids])
    end
  end
  
  # Given either a string id or a message returns the corresponding message
  def self.get_message(msg_or_id)
    if msg_or_id.class == String
      return self.find_by_id(msg_or_id) 
    else
      return msg_or_id
    end
  end
  

end
