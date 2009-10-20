require 'rexml/document'

class IncomingController < QSTController
  # HEAD /qst/:application_id/incoming
  def index
    if request.head?
      msg = ATMessage.last(
        :order => :timestamp, 
        :conditions => ['application_id = ?', @application.id])
      etag = msg.nil? ? '' : msg.guid
      head :ok, 'ETag' => etag
    else
      head :not_found
    end
  end
  
  # POST /qst/:application_id/incoming
  def create
    xml_data = request.env['RAW_POST_DATA']
    doc = REXML::Document.new(xml_data)
    
    last_id = nil
    
    doc.elements.each 'messages/message' do |elem|
      msg = ATMessage.new
      msg.application_id = @application.id
      msg.from = elem.attributes['from']
      msg.to = elem.attributes['to']
      msg.body = elem.elements['text'].text
      msg.guid = elem.attributes['id']
      msg.timestamp = Time.parse(elem.attributes['when'])
      msg.save
      
      last_id = msg.guid
    end
    
    head :ok, 'ETag' => last_id
  end
end
