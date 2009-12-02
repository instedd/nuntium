class PullQstMessageJob
  
  BATCH_SIZE = 10
  
  def initialize(app_id)
    @application_id = app_id
  end
  
  def perform
    begin
      result = perform_batch
    end while result == :success_pending
    result
  end
  
  def perform_batch
    require 'uri'
    require 'net/http'
    require 'builder'

    app = Application.find_by_id(@application_id)
    err = validate_app(app)
    return err unless err.nil?

    app.logger.starting_qst_push app.configuration[:url]
    
    # Create http requestor and uri
    http, path = create_http app, 'outgoing' 
    if http.nil? then return :error_initializing_http end
    path += "?max=#{BATCH_SIZE}"  
    
    # Get messages from server
    response = request_messages(app, http, path) 
    
    # Handle different responses
    if response.code == "304" # not modified
      app.logger.no_new_messages
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
      app.logger.pulled_n_messages size, last_new_id
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
  end
  
  # Validates application for QST
  # TODO: Move to a QST helper
  def validate_app(app)
    if app.nil?
      app.logger.app_not_found
      return :error_no_application
    elsif app.configuration.nil? or app.configuration[:url].nil?
      app.logger.no_url_in_configuration
      return :error_no_url_in_configuration
    elsif not app.interface == 'qst'
      app.logger.wrong_interface 'qst', app.interface
      return :error_wrong_interface
    end
    nil
  end
  
  # Initialize http connection
  # TODO: Move to a QST helper
  def create_http(app, target=nil)
    begin
      uri = URI.parse(app.configuration[:url]) 
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    rescue => e
      app.logger.error_initializing_http e
      app.set_last_at_guid nil
      return nil, nil
    else
      path = uri.path
      if not target.nil?
        path += '/' unless path.nil? or path.empty? or path[-1..-1] == '/'
        path += target
      end
      return http, path  
    end
  end
  
  # Enqueues jobs of this class for each qst push interface
  def self.enqueue_for_all_interfaces
    Application.find_all_by_interface('qst').each do |app|
      job = PullQstMessageJob.new(app.id)
      Delayed::Job.enqueue job
    end
  end
  
end