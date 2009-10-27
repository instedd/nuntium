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
          
          # Keep the ones after the etag
          outgoing_messages = outgoing_messages[count ... outgoing_messages.length]
          break
        end
      end
    end
    
    # Keep only max of them
    if !max.nil?
      outgoing_messages = outgoing_messages[0 ... max.to_i]
    end
    
    # Keep only ids of messages
    outgoing_messages.collect! {|x| x.guid }
    
    conditions = ['guid IN (?) and state != ?', outgoing_messages, 'failed']
    
    # Retrieve the messages using those ids
    @ao_messages = AOMessage.all(
      :order => 'timestamp', 
      :conditions => conditions)
    
    # Using ids instead of guids to increment tries should be faster
    # because it's a primary key against an index
    ao_messages_ids = @ao_messages.collect {|x| x.id}
      
    # Update their number of retries
    AOMessage.update_all('tries = tries + 1', ['id IN (?)', ao_messages_ids])
    
    # Separate messages into ones that have their tries
    # over max_tries and those still valid.
    valid_messages, invalid_message_ids = filter_tries_exceeded_and_not_exceeded @ao_messages, @application
    
    # Mark as failed messages that have their tries over max_tries
    if !invalid_message_ids.empty?
      AOMessage.update_all(['state = ?', 'failed'], ['id IN (?)', invalid_message_ids])
    end
    
    @ao_messages = valid_messages
    
    if !@ao_messages.empty?
      response.headers['ETag'] = @ao_messages.last.guid
    end
  end
end
