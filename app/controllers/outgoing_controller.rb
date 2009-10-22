class OutgoingController < QSTController
  # GET /qst/:application_id/outgoing
  def index
    etag = request.env['HTTP_IF_NONE_MATCH']
    max = params[:max]
    
    # Read outgoing messages
    outgoing_messages = QSTOutgoingMessage.all(
      :order => :id, 
      :conditions => ['channel_id = ?', @channel.id])

    # Remove entries previous to etag    
    if !etag.nil?
      count = 0
      outgoing_messages.each do |msg|
        count += 1
        if msg.guid == etag
        
          # Delete from qst queue
          QSTOutgoingMessage.delete_all(
            ["channel_id =? AND id <= ?", @channel.id, msg.id])

          # And also mark messages as delivered
          delivered_messages = outgoing_messages[0 ... count]
          delivered_messages.collect! {|x| x.guid}
          AOMessage.update_all(['state = ?', 'delivered'], ['guid in (?)', delivered_messages])
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
    
    conditions = ['guid IN (?)', outgoing_messages]
    
    # Retrieve the messages using those ids
    @ao_messages = AOMessage.all(
      :order => 'timestamp', 
      :conditions => conditions)
      
    # Update their number of retries
    AOMessage.update_all('tries = tries + 1', conditions)
    
    # Separate messages into ones that have their tries
    # over max_tries and those still valid.
    valid_messages = []
    invalid_message_guids = []
    
    @ao_messages.each do |msg|
      if msg.tries >= @application.max_tries
        invalid_message_guids += [msg.guid]
      else
        valid_messages += [msg]
      end
    end
    
    # Delete messages that have their tries over max_tries
    if !invalid_message_guids.empty?
      AOMessage.delete_all(["guid IN (?)", invalid_message_guids])
    end
    
    @ao_messages = valid_messages
    
    if !@ao_messages.empty?
      response.headers['ETag'] = @ao_messages.last.guid
    end
  end
end
