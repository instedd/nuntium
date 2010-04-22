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
    tree = request.POST.present? ? request.POST : Hash.from_xml(request.raw_post).with_indifferent_access
    
    last_id = nil
    
    messages = tree[:messages][:message]
    messages = [messages] if messages.class <= Hash 
    
    messages.each do |elem|
      msg = ATMessage.new
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
      
      @account.accept msg, @channel
      
      last_id = msg.guid
    end
    
    head :ok, 'ETag' => last_id
  end
end
