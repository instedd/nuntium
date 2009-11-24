class PushQstMessageJob
  
  BATCH_SIZE = 10
  
  def initialize(app_id)
    @application_id = app_id
  end
  
  def perform
    app = Application.find_by_id(@application_id)
    app.logger.starting_qst_push
   
    # Check configuration url is not empty
    if app.configuration.nil? or app.configuration[:url].nil?
      app.logger.no_url_in_configuration
      return :no_url_in_configuration
    end
    
    require 'uri'
    require 'net/http'
    require 'builder'
    
    # Create http requestor and uri
    uri, http = create_uri_and_http app 
    if http.nil? then return :error_initializing_http end 
    
    # If last transfer failed get last expected id from server
    last_msg = process_last_id app, http
    return last_msg if last_msg == :error_obtaining_last_id
    
    # Get newer messages
    new_msgs = ATMessage.fetch_app_newer_messages(@application_id, last_msg, false, BATCH_SIZE)
    
    # If there are no newer messages, finish
    if new_msgs.length == 0
      app.logger.no_new_messages
      app.set_last_ok true
      return :no_new_messages
    end

    # Push the new messages to the endpoint
    success = post_msgs app, http, new_msgs
    
    # Mark new status for messages based on post result increasing retries
    ATMessage.update_msgs_status new_msgs, app.max_tries, success
    
    # Save changes to the app
    app.set_last_ok success
    
    success ? :success : :failed
    
  end
  
  # Obtains last id from server if necessary
  # * marks older messages as confirmed if obtained last id
  # * returns last message or :error symbol
  def process_last_id(app, http)
    if app.configuration[:last_ok].nil?
      begin
        response = http.head 'incoming'
        if not response.code[0,1] == '2'
          app.logger.error_obtaining_last_id response.message
          return :error_obtaining_last_id
        else
          last_id = response['etag']  
        end
      rescue => e
        app.logger.error_obtaining_last_id e.message
        return :error_obtaining_last_id
      else
        last_msg = ATMessage.mark_older_as_confirmed(app.id, last_id)
        return last_msg
      end
    else
      return nil
    end  
  end
  
  # Initialize http connection
  def create_uri_and_http(app)
    begin
      user = app.configuration[:cred_user]
      pass = app.configuration[:cred_pass]
      uri = URI.parse app.configuration[:url]
      http = Net::HTTP.new(uri.host, uri.port)
      if not user.nil? and not pass.nil? then http.basic_auth user, pass end
    rescue => e
      app.logger.error_initializing_http e
      app.set_last_ok false
      return [nil, nil]
    else
      return [uri, http]  
    end
  end
  
  # Post all specified messages to the server as xml
  def post_msgs(app, http, msgs)
    # Write the xml
    xml = Builder::XmlMarkup.new(:indent => 1)
    xml.instruct!
    xml.messages do
      msgs.each do |msg|
        msg.write_xml xml
      end
    end
    # Make the post and check for response code
    response = http.post 'incoming', xml.target!, { 'Content-Type' => 'text/xml' }
    if not response.code[0,1] == '2'
      app.logger.error_posting_msgs response.message
      return false
    end
  rescue => e
    app.logger.error_posting_msgs e
    return false
  else
    app.logger.pushed_n_messages msgs.length
    return true
  end
  
  # Make a head request to obtain last id from server
  def request_last_id(http)
    response = http.head 'incoming'
    return response['etag']
  end
  
  # Enqueues jobs of this class for each qst push interface
  def self.enqueue_for_all_interfaces
    Application.find_all_by_interface('qst').each do |app|
      job = PushQstMessageJob.new(app_id)
      Delayed::Job.enqueue job
    end
  end
  
end