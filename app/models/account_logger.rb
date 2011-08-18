class AccountLogger
  def initialize(account_id, application_id = nil)
    @account_id = account_id
    @application_id = application_id
  end

  def at_message_delivery_succeeded(msg, interface)
    info(:at_message_id => msg.id, :channel_id => msg.channel_id, :message => "Try ##{msg.tries} for delivering message through interface #{interface} succeeded")
  end

  def at_message_delivery_exceeded_tries(msg, interface)
    info(:at_message_id => msg.id, :channel_id => msg.channel_id, :message => "Try ##{msg.tries} for delivering message through interface #{interface} exceeded maximum number of tries")
  end

  def ao_message_delivery_succeeded(msg, channel)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Try ##{msg.tries} for delivering message through channel #{channel} succeeded")
  end

  def ao_message_delivery_exceeded_tries(msg, channel)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Try ##{msg.tries} for delivering message through channel #{channel} exceeded maximum number of tries")
  end

  def ao_message_received(msg, interface)
    if interface.class == Hash and interface[:account].class == Account
      info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message received from account '#{interface[:account].name}'")
    elsif interface == 're-route'
      info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message was re-routed")
    else
      info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "Message received via #{interface} interface")
    end
  end

  def ao_message_status_receieved(msg, status)
    info(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "#{status} received from server")
  end

  def ao_message_status_warning(msg, status)
    warning(:ao_message_id => msg.id, :channel_id => msg.channel_id, :message => "#{status} received from server")
  end

  def error_routing_msg(ao_msg, e)
    error(:message => "Error routing message '#{e.to_s}'", :ao_message_id => ao_msg.id, :channel_id => ao_msg.channel_id)
  end

  def error_obtaining_last_id(message)
    error(:message => "Error obtaining last id from server in QST operation: '#{message}'")
  end

  def error_initializing_http(exception)
    error(:message => "Error initializing http connection in QST operation: '#{exception_msg(exception)}'")
  end

  def error_posting_msgs(msg)
    error(:message => "Error posting messages to server in QST operation: '#{msg}'")
  end

  def error_pulling_msgs(msg)
    error(:message => "Error pulling messages from server in QST operation: '#{msg}'")
  end

  def error_processing_msgs(msg)
    error(:message => "Error processing messages from server in QST operation: '#{msg}'")
  end

  def info(hash_or_message)
    create(hash_or_message, Log::Info)
  end

  def warning(hash_or_message)
    create(hash_or_message, Log::Warning)
  end

  def error(hash_or_message)
    create(hash_or_message, Log::Error)
  end

  def self.exception_in_channel(channel, exception)
    logger = AccountLogger.new channel.account_id
    logger.error :channel_id => channel.id, :message => "#{logger.exception_msg(exception)}"
  end

  def exception_in_channel_and_ao_message(channel, ao_msg, exception)
    error :channel_id => channel.id, :ao_message_id => ao_msg.id, :message => "Try ##{ao_msg.tries} for delivering message through #{channel.kind} channel '#{channel.name}' failed: #{exception_msg(exception)}"
  end

  def exception_in_application_and_at_message(application, at_msg, exception)
    error :application_id => application.id, :at_message_id => at_msg.id, :message => "Try ##{at_msg.tries} for delivering message to application '#{application.name}' failed: #{exception_msg(exception)}"
  end

  def message_channeled(ao_msg, channel)
    info :channel_id => channel.id, :ao_message_id => ao_msg.id, :message => "Try ##{ao_msg.tries} for delivering message through #{channel.kind} channel '#{channel.name}' succeeded"
  end

  def create(hash_or_message, severity)
    if hash_or_message.class.to_s == 'String'
      hash_or_message = {:message => hash_or_message}
    end

    now = Time.now.utc.to_s(:db)
    message = (hash_or_message[:message] || "").gsub("'", "''")

    insert = "INSERT INTO logs (account_id, application_id, channel_id, ao_message_id, at_message_id, message, severity, created_at, updated_at) VALUES (#{@account_id}, #{@application_id || hash_or_message[:application_id] || "NULL"}, #{hash_or_message[:channel_id] || "NULL"},#{hash_or_message[:ao_message_id] || "NULL"},#{hash_or_message[:at_message_id] || "NULL"},'#{message}',#{severity},'#{now}','#{now}')"

    Log.connection.execute insert
  end

  def exception_msg(exception)
    if exception.class == String || exception.class == RuntimeError
      exception
    else
      "#{exception.class} - #{exception}"
    end
  end

end
