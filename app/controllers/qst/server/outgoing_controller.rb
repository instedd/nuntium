class OutgoingController < QSTServerController
  # GET /qst/:application_id/outgoing
  def index
    etag = request.env['HTTP_IF_NONE_MATCH']
    max = params[:max]
    sql = ActiveRecord::Base.connection
    
    # Default max to 10 if not specified
    max = max.nil? ? 10 : max.to_i
    
    # If there's an etag
    if !etag.nil?
  	  # Find the message by guid
  	  last = AOMessage.find_by_guid(etag, :select => 'id')
      if !last.nil?
        # Mark messsages as delivered
        sql = ActiveRecord::Base.connection()
        sql.execute(
          "UPDATE ao_messages " <<
          "SET state = 'delivered' " << 
          "WHERE id IN " <<
          "(SELECT ao_message_id FROM qst_outgoing_messages WHERE channel_id = #{@channel.id} AND ao_message_id <= #{last.id})"
          )
        
        # Delete previous messages in qst including it
        sql.execute("DELETE FROM qst_outgoing_messages WHERE channel_id = #{@channel.id} AND ao_message_id <= #{last.id}")
      end
    end
    
    # Loop while we have invalid messages
    begin
      # Read outgoing messages
      @ao_messages = nil
      
      # We need to do this query uncached in case we get back here in the loop
      # so as to not get the same messages again.
      ActiveRecord::Base.uncached do
        @ao_messages = AOMessage.all(
          :order => 'qst_outgoing_messages.id',
          :joins => 'INNER JOIN qst_outgoing_messages ON ao_messages.id = qst_outgoing_messages.ao_message_id',
          :conditions => "qst_outgoing_messages.channel_id = #{@channel.id}",
          :limit => max)
      end
        
      if !@ao_messages.empty?
        # Separate messages into ones that have their tries
        # over max_tries and those still valid.
        valid_messages, invalid_messages = filter_tries_exceeded_and_not_exceeded @ao_messages, @application
        
        # Mark as failed messages that have their tries over max_tries
        if !invalid_messages.empty?
          invalid_message_ids = invalid_messages.map(&:id).join(',')
          sql.execute("UPDATE ao_messages SET state = 'failed' WHERE id IN (#{invalid_message_ids})")
          sql.execute("DELETE FROM qst_outgoing_messages WHERE ao_message_id IN (#{invalid_message_ids})") 
          invalid_messages.each do |message|
            @application.logger.ao_message_delivery_exceeded_tries message, 'qst_server'
          end
        end
      end
    end until @ao_messages.empty? || invalid_messages.empty?  
    
    if !@ao_messages.empty?
      # Update their number of retries
      sql.execute("UPDATE ao_messages SET tries = tries + 1 WHERE id IN (#{@ao_messages.map(&:id).join(',')})")
      
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
