require 'rexml/document'

class IncomingController < QSTController
  # HEAD /qst/:application_id/incoming
  def index
    return head(:not_found) if !request.head?
    
    msg = @application.last_at_message
    etag = msg.nil? ? nil : msg.guid
    head :ok, 'ETag' => etag
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
      msg.state = 'queued'
      msg.save
      
      last_id = msg.guid
    end
    
    head :ok, 'ETag' => last_id
  end
end
