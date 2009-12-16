class PullQstMessageJob
  
  BATCH_SIZE = 10
  
  require 'qst_common'
  include ClientQstJob
  
  def initialize(app_id)
    @application_id = app_id
  end
  
  def perform_batch
    require 'uri'
    require 'net/http'
    require 'builder'

    app = Application.find_by_id(@application_id)
    err = validate_app(app)
    return err unless err.nil?

    # Create http requestor and uri
    http, path = create_http app, 'outgoing' 
    if http.nil? then return :error_initializing_http end
    path += "?max=#{BATCH_SIZE}"  
    
    # Get messages from server
    response = request_messages(app, http, path) 
    
    # Handle different responses
    if response.nil?
      return :error_pulling_messages
    elsif response.code == "304" # not modified
      RAILS_DEFAULT_LOGGER.info "Pull QST in application #{app.name}: no new messages"
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
      AOMessage.parse_xml response.body do |msg|
        app.route(msg)
        last_new_id = msg.guid
        size+= 1
      end
    rescue => e
      # On error, save last processed ok and quit
      app.logger.error_processing_msgs e.to_s
      app.set_last_ao_guid(last_new_id) unless last_new_id.nil?
      return :error_processing_messages
    else
      # On success, update last id and return success or pending
      if etag.nil?
        RAILS_DEFAULT_LOGGER.info "Pull QST in application #{app.name}: polled '#{size}' messages to server"
      else
        RAILS_DEFAULT_LOGGER.info "Pull QST in application #{app.name}: polled '#{size}' messages to server up to id '#{last_new_id}'"
      end
      app.set_last_ao_guid(last_new_id) unless last_new_id.nil?
      return size < BATCH_SIZE ? :success : :success_pending 
    end
  
  end
  
  # Creates a get request with proper authentication
  def request_messages app, http, path
    last_id = app.configuration[:last_ao_guid]
    user = app.configuration[:cred_user]
    pass = app.configuration[:cred_pass]
    request = Net::HTTP::Get.new path
    request.basic_auth(user, pass) unless user.nil? or pass.nil?
    request['if-none-match'] = last_id unless last_id.nil?
    http.request request
  rescue => err
    app.logger.error :message => "Error getting messages from the server: " + err.to_s
    return nil
  end
  
  # Enqueues jobs of this class for each qst push interface
  def self.enqueue_for_all_interfaces
    Application.find_all_by_interface('qst').each do |app|
      job = PullQstMessageJob.new(app.id)
      Delayed::Job.enqueue job
    end
  end
  
end