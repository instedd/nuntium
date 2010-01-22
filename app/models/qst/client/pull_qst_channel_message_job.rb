class PullQstChannelMessageJob
  
  BATCH_SIZE = 10
  
  include ClientQstJob
  
  def initialize(app_id, channel_id)
    @application_id = app_id
    @channel_id = channel_id
  end
  
  def perform_batch
    require 'uri'
    require 'net/http'
    require 'builder'

    app = Application.find_by_id(@application_id)
    channel = Channel.find_by_id(@channel_id)
    err = validate_channel(channel)
    cfg = ClientQstConfiguration.new(channel)
    return err unless err.nil?

    # Create http requestor and uri
    http, path = create_http cfg, 'outgoing' 
    if http.nil? then return :error_initializing_http end
    path += "?max=#{BATCH_SIZE}"  
    
    # Get messages from server
    response = request_messages(app, channel, cfg, http, path) 
    
    # Handle different responses
    if response.nil?
      return :error_pulling_messages
    elsif response.code == "304" # not modified
      RAILS_DEFAULT_LOGGER.info "Pull QST in channel #{@channel_id}: no new messages"
      return :success
    elsif response.code[0,1] != "2" # not success
      app.logger.error_pulling_msgs response.message
      return :error_pulling_messages
    end
    
    # Accumulators
    last_new_id = nil
    size = 0
    
    begin
      # Process successfully downloaded messages
      ATMessage.parse_xml response.body do |msg|
        msg.application_id = @application_id
        msg.channel_id = @channel_id
        msg.state = 'queued'
        msg.save
        
        app.logger.at_message_received_via_channel msg, channel
        
        last_new_id = msg.guid
        size+= 1
      end
    rescue => e
      # On error, save last processed ok and quit
      app.logger.error_processing_msgs e.to_s
      cfg.set_last_at_guid(last_new_id) unless last_new_id.nil?
      return :error_processing_messages
    else
      # On success, update last id and return success or pending
      if last_new_id.nil?
        RAILS_DEFAULT_LOGGER.info "Pull QST in channel #{@channel_id}: pulled '#{size}' messages from server"
      else
        RAILS_DEFAULT_LOGGER.info "Pull QST in channel #{@channel_id}: pulled '#{size}' messages from server up to id '#{last_new_id}'"
      end
      cfg.set_last_at_guid(last_new_id) unless last_new_id.nil?
      return size < BATCH_SIZE ? :success : :success_pending 
    end
  
  end
  
  # Creates a get request with proper authentication
  def request_messages app, channel, cfg, http, path
    last_id = cfg.last_at_guid
    user = cfg.user
    pass = cfg.pass
    request = Net::HTTP::Get.new path
    request.basic_auth(user, pass) unless user.nil? or pass.nil?
    request['if-none-match'] = last_id unless last_id.nil?
    http.request request
  rescue => err
    cfg.logger.error :message => "Error getting messages from the server: " + err.to_s
    return nil
  end
  
  # Enqueues jobs of this class for each qst push interface
  def self.enqueue_for_all_interfaces
    Channel.find_each(:conditions => "kind = 'qst_client'") do |chan|
      job = PullQstChannelMessageJob.new(chan.application_id, chan.id)
      Delayed::Job.enqueue job
    end
  end
  
end