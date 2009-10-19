class OutgoingController < ApplicationController
  # GET /qst/outgoing
  def index
    etag = request.env['HTTP_IF_NONE_MATCH']
    max = params[:max]
    
    # Read outgoing messages
    outgoing_messages = QSTOutgoingMessage.all(:order => :id)

    # Remove entries previous to etag    
    if !etag.nil?
      count = 0
      outgoing_messages.each do |msg|
        count += 1
        if msg.guid == etag
          QSTOutgoingMessage.delete_all("id <= #{msg.id}")
          break
        end
      end
      
      # Keep the ones after the etag
      outgoing_messages = outgoing_messages[count ... outgoing_messages.length]
    end
    
    # Keep only max of them
    if !max.nil?
      outgoing_messages = outgoing_messages[0 ... max.to_i]
    end
    
    # Keep only ids of messages
    outgoing_messages.collect! {|x| x.guid }
    
    @ao_messages = AOMessage.all(:order => 'timestamp', :conditions => ['guid IN (?)', outgoing_messages])
    
    if !@ao_messages.empty?
      response.headers['ETag'] = @ao_messages.last.guid
    end
  end
end
