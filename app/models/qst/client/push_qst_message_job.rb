class PushQstMessageJob
  
  BATCH_SIZE = 10
  
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
    http, path = create_http app, 'incoming' 
    if http.nil? then return :error_initializing_http end 
    
    # If last transfer failed get last expected id from server
    last_msg = process_last_id app, http, path
    return :error_obtaining_last_id if last_msg == :error_obtaining_last_id
    
    # Get newer messages
    new_msgs = ATMessage.fetch_app_newer_messages(@application_id, last_msg, false, BATCH_SIZE)
    
    # If there are no newer messages, finish
    if new_msgs.length == 0
      RAILS_DEFAULT_LOGGER.info "Push QST in application #{app.name}: no new messages"
      app.set_last_at_guid(last_msg.guid) unless last_msg.nil?
      return :success
    end

    # Push the new messages to the endpoint
    last_id = post_msgs app, http, path, new_msgs
    
    # Mark new status for messages based on post result increasing retries
    ATMessage.update_msgs_status new_msgs, app.max_tries, last_id
    
    # Logging: say that valid messages were returned and invalid no
    ATMessage.log_delivery(new_msgs, app, 'qst_client')
    
    # Save changes to the app
    app.set_last_at_guid last_id
    
    # Return value depending success and whether must continue or not
    if last_id.nil?
      return :failed
    elsif new_msgs.length < BATCH_SIZE
      return :success
    else
      return :success_pending
    end
    
  end
  
  # Obtains last id from server if necessary
  # * marks older messages as confirmed if obtained last id
  # * returns nil if last id does not belong to any known messages
  # * returns last message or :error symbol
  def process_last_id(app, http, path)
    if app.configuration[:last_at_guid].nil?
      begin
        user = app.configuration[:cred_user]
        pass = app.configuration[:cred_pass]
        request = Net::HTTP::Head.new path
        request.basic_auth(user, pass) unless user.nil? or pass.nil?
        response = http.request request
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
        return nil if last_id.nil?
        last_msg = ATMessage.find_by_guid last_id
        if last_msg.nil?
          app.logger.error_obtaining_last_id "Invalid guid #{last_id}" 
          return nil # if we don't know which message the server is talking about, send everything
        else
          ATMessage.mark_older_as_confirmed(app.id, last_msg)
          return last_msg
        end
      end
    else
      return nil
    end  
  end
  

  # Post all specified messages to the server as xml
  def post_msgs(app, http, path, msgs)
    # Obtain data
    xml = ATMessage.write_xml msgs
    user = app.configuration[:cred_user]
    pass = app.configuration[:cred_pass]
    # Make the request
    request = Net::HTTP::Post.new path
    request.basic_auth(user, pass) unless user.nil? or pass.nil?
    request['Content-Type'] = 'text/xml'
    response = http.request request, xml
    # Handle response
    if not response.code[0,1] == '2'
      app.logger.error_posting_msgs response.message
      return nil
    end
  rescue => e
    app.logger.error_posting_msgs e
    return nil
  else
    etag = response['etag']
    if etag.nil?
      RAILS_DEFAULT_LOGGER.info "Push QST in application #{app.name}: posted '#{msgs.length}' messages to server"
    else
      RAILS_DEFAULT_LOGGER.info "Push QST in application #{app.name}: posted '#{msgs.length}' messages to server up to id '#{etag}'"
    end
    return etag
  end
  
  # Enqueues jobs of this class for each qst push interface
  def self.enqueue_for_all_interfaces
    Application.find_all_by_interface('qst_client').each do |app|
      job = PushQstMessageJob.new(app.id)
      Delayed::Job.enqueue job
    end
  end
  
end