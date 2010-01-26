class OutgoingController < QSTServerController
  # GET /qst/:application_id/outgoing
  def index
    etag = request.env['HTTP_IF_NONE_MATCH']
    max = params[:max]
    
    # Default max to 10 if not specified
    if max.nil?
      max = 10
    else
      max = max.to_i
    end
    
    # If there's an etag
    if !etag.nil?
	
	  # Find the message by guid
	  msg = AOMessage.find_by_guid(etag)
	
	  if msg.nil?
	    last = nil
	  else
        # Find the message in qst for that etag
        last = QSTOutgoingMessage.first(
          :order => :id, 
          :conditions => ['channel_id = ? AND ao_message_id = ?', @channel.id, msg.id])
      end
        
      if !last.nil?
        # Mark messsages as delivered
        sql = ActiveRecord::Base.connection();
        sql.execute(
          "UPDATE ao_messages " + 
          "SET state = 'delivered' " + 
          "WHERE id IN " +
          "(SELECT ao_message_id FROM qst_outgoing_messages WHERE id <= " + last.id.to_s + ")"
          )
        
        # Delete previous messages in qst including it
        QSTOutgoingMessage.delete_all(
            ["channel_id =? AND id <= ?", @channel.id, last.id])
      end
    end
    
    # Read outgoing messages
    @ao_messages = AOMessage.all(
      :order => 'qst_outgoing_messages.id',
      :joins => 'INNER JOIN qst_outgoing_messages ON ao_messages.id = qst_outgoing_messages.ao_message_id',
      :conditions => 'qst_outgoing_messages.channel_id = ' + @channel.id.to_s,
      :limit => max)
      
    if !@ao_messages.empty?
      # Using ids to increment tries
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
      
      # Logging: say that valid messages were returned and invalid no
      @ao_messages.each do |msg|
        if msg.tries >= @application.max_tries
          @application.logger.ao_message_delivery_succeeded msg, 'qst_server'
        else
          @application.logger.ao_message_delivery_exceeded_tries msg, 'qst_server'
        end
      end
      
      @ao_messages = valid_messages
      @ao_messages.sort! {|x,y| x.timestamp <=> y.timestamp}
    end
    
    if !@ao_messages.empty?
      response.headers['ETag'] = @ao_messages.last.id
    end
	
	render :layout => false
  end
end
