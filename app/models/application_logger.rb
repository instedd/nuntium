class ApplicationLogger
  def initialize(application_id)
    @application_id = application_id
  end
  
  def protocol_not_found_for(ao_msg)
    error(:ao_message_id => ao_msg.id, :message => "Protocol not found in 'to' field")
  end

  def wrong_interface(expected, actual)
    error(:message => 'Found interface #{actual} when expecting #{expected}')
  end
  
  def no_channel_found_for(protocol, ao_msg)
    error(:ao_message_id => ao_msg.id, :message => "No channel found for protocol '#{protocol}'")
  end
  
  def app_not_found(app_id=nil)
    if app_id.nil?
      error(:message => "Application not found")
    else
      error(:message => "Application with id '#{app_id}' not found")
    end
      
  end
  
  def no_url_in_configuration()
    error(:message => 'No url found in application configuration for pushing/pulling messages')
  end

  def error_obtaining_last_id(message)
    error(:message => "Error obtaining last id from server: '#{message}'")
  end

  def error_initializing_http(exception)
    error(:message => "Error initializing http connection: '#{exception.message}'")
  end
  
  def error_posting_msgs(msg)
    error(:message => "Error posting messages to server: '#{msg}'")
  end
  
  def error_pulling_msgs(msg)
    error(:message => "Error pulling messages from server: '#{msg}'")
  end
  
  def error_processing_msgs(msg)
    error(:message => "Error processing messages from server: '#{msg}'")
  end

  def more_than_one_channel_found_for(protocol, ao_msg)
    warning(:ao_message_id => ao_msg.id, :message => "More than one channel found for protocol '#{protocol}'")
  end

  def starting_qst_push(uri)
    info(:message => "Starting new QST push job to server #{uri}")
  end

  def starting_qst_pull(uri)
    info(:message => "Starting new QST pull job from server #{uri}")
  end

  def pushed_n_messages(n, last_id = nil)
    if last_id.nil?
      info(:message => "Posted '#{n}' messages to server")
    else
      info(:message => "Posted '#{n}' messages to server up to id '#{last_id}'")
    end
  end

  def pulled_n_messages(n, last_id = nil)
    if last_id.nil?
      info(:message => "Pulled '#{n}' messages from server")
    else
      info(:message => "Pulled '#{n}' messages from server up to id '#{last_id}'")
    end
  end

  def no_new_messages
    info(:message => 'No new messages to push/pull to the server')
  end
  
  def info(hash_or_message)
    create(hash_or_message, ApplicationLog::Info)
  end
  
  def warning(hash_or_message)
    create(hash_or_message, ApplicationLog::Warning)
  end
  
  def error(hash_or_message)
    create(hash_or_message, ApplicationLog::Error)
  end
  
  def self.exception_in_channel(channel, exception)
    logger = ApplicationLogger.new(channel.application_id)
    logger.error(:channel_id => channel.id, :message => exception.message)
  end
  
  def self.exception_in_channel_and_ao_message(channel, ao_msg, exception)
    logger = ApplicationLogger.new(channel.application_id)
    logger.error(:channel_id => channel.id, :ao_message_id => ao_msg.id, :message => exception.message)
  end
  
  def create(hash_or_message, severity)
    if hash_or_message.class.to_s == 'String'
      hash_or_message = {:message => hash_or_message}
    end
    hash_or_message[:application_id] = @application_id
    hash_or_message[:severity] = severity
    puts hash_or_message if ENV['RAILS_ENV'] == 'test'
    ApplicationLog.create(hash_or_message)
  end
end