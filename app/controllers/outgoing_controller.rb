class OutgoingController < ApplicationController
  before_filter :authenticate

  # GET /qst/outgoing
  def index
    etag = request.env['HTTP_IF_NONE_MATCH']
    max = params[:max]
    
    # Read outgoing messages
    outgoing_messages = QSTOutgoingMessage.all(:order => :id, :conditions => ['channel_id = ?', @channel.id])

    # Remove entries previous to etag    
    if !etag.nil?
      count = 0
      outgoing_messages.each do |msg|
        count += 1
        if msg.guid == etag
          QSTOutgoingMessage.delete_all(["channel_id =? AND id <= ?", @channel.id, msg.id])
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
  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @application = Application.first(:conditions => ['name = ?', username]) 
      if !@application.nil?
        @channel = @application.channels.first(:conditions => ['kind = ?', :qst])
        !@channel.nil? and @channel.configuration[:password] == password
      else
        false
      end
    end
  end
end
