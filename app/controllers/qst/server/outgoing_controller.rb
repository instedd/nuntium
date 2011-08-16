class OutgoingController < QSTServerController
  # GET /qst/:account_id/outgoing
  def index
    etag = request.env['HTTP_IF_NONE_MATCH']
    max = params[:max]

    # Default max to 10 if not specified
    max = max.nil? ? 10 : max.to_i

    # If there's an etag
    if !etag.nil?
      # Find the message by guid
      last = AOMessage.select('id').find_by_guid etag
      if !last.nil?
        # Mark messsages as delivered
        outs = @channel.qst_outgoing_messages.select(:ao_message_id).where 'ao_message_id <= ?', last.id
        outs.each do |out|
          AOMessage.where(:id => out.ao_message_id, :state => 'queued').update_all "state = 'delivered'"
        end

        # Delete previous messages in qst including it
        outs.delete_all
      end
    end

    # Loop while we have invalid messages
    begin
      # Read outgoing messages
      @ao_messages = nil

      # We need to do this query uncached in case we get back here in the loop
      # so as to not get the same messages again.
      ActiveRecord::Base.uncached do
        @ao_messages = AOMessage.
          joins('INNER JOIN qst_outgoing_messages ON ao_messages.id = qst_outgoing_messages.ao_message_id').
          order('qst_outgoing_messages.id').
          where("state = ? AND qst_outgoing_messages.channel_id = ?", 'queued', @channel.id).
          limit(max).all
      end

      if @ao_messages.present?
        # Separate messages into ones that have their tries
        # over max_tries and those still valid.
        valid_messages, invalid_messages = filter_tries_exceeded_and_not_exceeded @ao_messages, @account

        # Mark as failed messages that have their tries over max_tries
        if !invalid_messages.empty?
          invalid_messages.each do |invalid_message|
            AOMessage.where(:id => invalid_message.id).update_all "state = 'failed'"
            QSTOutgoingMessage.where(:ao_message_id => invalid_message.id).delete_all
          end
          invalid_messages.each do |message|
            @account.logger.ao_message_delivery_exceeded_tries message, 'qst_server'
          end
        end
      end
    end until @ao_messages.empty? || invalid_messages.empty?

    # Update their number of retries and say that valid messages were returned
    @ao_messages.each do |message|
      AOMessage.where(:id => message.id).update_all 'tries = tries + 1'
      @account.logger.ao_message_delivery_succeeded message, 'qst_server'
    end

    @ao_messages.sort!{|x,y| x.timestamp <=> y.timestamp}

    @channel.invalidate_queued_ao_messages_count

    response.headers['Etag'] = @ao_messages.last.id.to_s if @ao_messages.present?
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
    render :text => AOMessage.write_xml(@ao_messages)
  end
end
