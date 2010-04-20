class PullQstMessageJob
  
  BATCH_SIZE = 10
  
  include ClientQstJob
  
  def initialize(account_id)
    @account_id = account_id
  end
  
  def perform_batch
    require 'uri'
    require 'net/http'
    require 'builder'

    account = Account.find_by_id(@account_id)
    cfg = ClientQstConfiguration.new(account)
    err = validate_account(account)
    return err unless err.nil?

    # Create http requestor and uri
    http, path = create_http cfg, 'outgoing' 
    if http.nil? then return :error_initializing_http end
    path << "?max=#{BATCH_SIZE}"  
    
    # Get messages from server
    response = request_messages(account, cfg, http, path) 
    
    # Handle different responses
    if response.nil?
      return :error_pulling_messages
    elsif response.code == "304" # not modified
      RAILS_DEFAULT_LOGGER.info "Pull QST in account #{account.name}: no new messages"
      return :success
    elsif response.code == "401" # Unauthorized
      account.alert "Pulling QST received unauthorized: invalid credentials"
    
      account.interface = 'rss'
      account.save!
      return
    elsif response.code[0,1] != "2" # not success
      account.logger.error_pulling_msgs response.message
      return :error_pulling_messages
    end
    
    # Accumulators
    last_new_id = nil
    size = 0
    
    begin
      # Process successfully downloaded messages
      AOMessage.parse_xml response.body do |msg|
        account.route msg, 'qst_client'
        last_new_id = msg.guid
        size += 1
      end
    rescue => e
      # On error, save last processed ok and quit
      account.logger.error_processing_msgs e.to_s
      account.set_last_ao_guid(last_new_id) unless last_new_id.nil?
      return :error_processing_messages
    else
      # On success, update last id and return success or pending
      if last_new_id.nil?
        RAILS_DEFAULT_LOGGER.info "Pull QST in account #{account.name}: polled '#{size}' messages to server"
      else
        RAILS_DEFAULT_LOGGER.info "Pull QST in account #{account.name}: polled '#{size}' messages to server up to id '#{last_new_id}'"
      end
      account.set_last_ao_guid(last_new_id) unless last_new_id.nil?
      return size < BATCH_SIZE ? :success : :success_pending 
    end
  
  end
  
  # Creates a get request with proper authentication
  def request_messages account, cfg, http, path
    last_id = cfg.last_ao_guid
    user = cfg.user
    pass = cfg.pass
    request = Net::HTTP::Get.new path
    request.basic_auth(user, pass) unless user.nil? or pass.nil?
    request['if-none-match'] = last_id unless last_id.nil?
    http.request request
  rescue => err
    account.logger.error :message => "Error getting messages from the server: #{err}"
    return nil
  end
  
end
