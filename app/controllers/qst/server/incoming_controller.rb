require 'rexml/document'

class IncomingController < QSTServerController
  # HEAD /qst/:account_id/incoming
  def index
    return head(:not_found) if !request.head?
    
    msg = ATMessage.last(:order => :timestamp, :conditions => ['account_id = ?', @account.id], :select => 'guid')
    etag = msg.nil? ? nil : msg.guid
    head :ok, 'ETag' => etag
  end
  
  # POST /qst/:account_id/incoming
  def create
    xml_data = request.env['RAW_POST_DATA']
    doc = REXML::Document.new(xml_data)
    
    last_id = nil
    
    doc.elements.each 'messages/message' do |elem|
      msg = ATMessage.new
      msg.from = elem.attributes['from']
      msg.to = elem.attributes['to']
      msg.body = elem.elements['text'].text
      msg.guid = elem.attributes['id']
      msg.timestamp = Time.parse(elem.attributes['when'])
      @account.accept msg, @channel
      
      last_id = msg.guid
    end
    
    head :ok, 'ETag' => last_id
  end
end
