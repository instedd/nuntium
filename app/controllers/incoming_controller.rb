require 'rexml/document'

class IncomingController < ApplicationController
  # GET /qst/incoming
  # HEAD /qst/incoming
  def index
    if request.head?
      msg = InMessage.last(:order => :timestamp)
      etag = msg.nil? ? '' : msg.guid
      head :ok, 'ETag' => etag
    else
      head :not_found
    end
  end
  
  # POST /qst/incoming
  def create
    xml_data = request.env['RAW_POST_DATA']
    doc = REXML::Document.new(xml_data)
    
    last_id = nil
    
    doc.elements.each 'messages/message' do |elem|
      msg = InMessage.new
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
