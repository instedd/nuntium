class OutgoingController < QSTServerController
  # GET /qst/:application_id/outgoing
  def index
    etag = request.env['HTTP_IF_NONE_MATCH']
    max = params[:max]
    
    # Default max to 10 if not specified
    max = max.nil? ? 10 : max.to_i
    
    # If there's an etag
    if !etag.nil?
  	  # Find the message by guid
  	  msg = AOMessage.find_by_guid(etag)
  	  if msg.nil?
  	    last = nil
  	  else
        # Find the message in qst for that etag
        last = QSTOutgoingMessage.last(
          :order => :id,
          :conditions => ['channel_id = ? AND ao_message_id = ?', @channel.id, msg.id])
      end
        
      if !last.nil?
        # Mark messsages as delivered
        sql = ActiveRecord::Base.connection();
        sql.execute(
          "UPDATE ao_messages " <<
          "SET state = 'delivered' " << 
          "WHERE id IN " <<
          "(SELECT ao_message_id FROM qst_outgoing_messages WHERE channel_id = #{@channel.id} AND id <= #{last.id})"
          )
        
        # Delete previous messages in qst including it
        QSTOutgoingMessage.delete_all(
            ["channel_id =? AND id <= ?", @channel.id, last.id])
      end
    end
    
    # Loop while we have invalid messages
    begin
      # Read outgoing messages
      @ao_messages = AOMessage.all(
        :order => 'qst_outgoing_messages.id',
        :joins => 'INNER JOIN qst_outgoing_messages ON ao_messages.id = qst_outgoing_messages.ao_message_id',
        :conditions => "qst_outgoing_messages.channel_id = #{@channel.id}",
        :limit => max)
        
      if !@ao_messages.empty?
        # Separate messages into ones that have their tries
        # over max_tries and those still valid.
        valid_messages, invalid_messages = filter_tries_exceeded_and_not_exceeded @ao_messages, @application
        
        # Mark as failed messages that have their tries over max_tries
        if !invalid_messages.empty?
          invalid_message_ids = invalid_messages.map(&:id)
          AOMessage.update_all(['state = ?', 'failed'], ['id IN (?)', invalid_message_ids])
          QSTOutgoingMessage.delete_all(['ao_message_id IN (?)', invalid_message_ids])
          invalid_messages.each do |message|
            @application.logger.ao_message_delivery_exceeded_tries message, 'qst_server'
          end
        end
      end
    end until @ao_messages.empty? || invalid_messages.empty?  
    
    if !@ao_messages.empty?
      # Update their number of retries
      AOMessage.update_all('tries = tries + 1', ['id IN (?)', @ao_messages.map(&:id)])
      
      # Logging: say that valid messages were returned
      @ao_messages.each do |message|
        @application.logger.ao_message_delivery_succeeded message, 'qst_server'
      end
      
      @ao_messages.sort! {|x,y| x.timestamp <=> y.timestamp}
    end 
    
    response.headers['ETag'] = @ao_messages.last.id.to_s if !@ao_messages.empty?
	  render :layout => false
  end
end
