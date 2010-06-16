require 'iconv'

class ClickatellController < AccountAuthenticatedController
  before_filter :authenticate, :only => :index
  before_filter :check_login, :only => :view_credit

  @@clickatell_timezone = ActiveSupport::TimeZone.new 2.hours

  # GET /clickatell/:account_id/incoming
  def index
    if params[:udh].present?
      udh = Udh.new(params[:udh].hex_to_bytes)
      return index_multipart_message udh if udh[0]
    end
    
    index_single_message
  end
  
  def view_credit
    id = params[:id]
    @channel = @account.find_channel id
    return redirect_to_home unless @channel && @channel.kind == 'clickatell'
    
    render :text => @channel.handler.get_credit
  end
  
  private
  
  def index_single_message
    create_message params[:text]
    head :ok
  end
  
  def index_multipart_message(udh)
    # Search other received parts
    conditions = ['originating_isdn = ? AND reference_number = ?', params[:from], udh[0][:reference_number]]
    parts = ClickatellMessagePart.all(:conditions => conditions)
    
    # If all other parts are there
    if parts.length == udh[0][:part_count] - 1
      # Add this new part, sort and get text
      parts.push ClickatellMessagePart.new(:part_number => udh[0][:part_number], :text => params[:text])
      parts.sort! { |x,y| x.part_number <=> y.part_number }
      text = parts.collect { |x| x.text }.to_s
      
      # Create message from the resulting text
      create_message text
      
      # Delete stored information
      ClickatellMessagePart.delete_all conditions
    else
      # Just save the part
      ClickatellMessagePart.create(
        :originating_isdn => params[:from],
        :reference_number => udh[0][:reference_number],
        :part_count => udh[0][:part_count],
        :part_number => udh[0][:part_number],
        :timestamp => get_timestamp,
        :text => params[:text]
        )
    end
    
    head :ok
  end
  
  def create_message(text)
    msg = ATMessage.new
    msg.from = "sms://#{params[:from]}"
    msg.to = "sms://#{params[:to]}"
    msg.subject = Iconv.new('UTF-8', params[:charset]).iconv(text)
    msg.channel_relative_id = params[:moMsgId]
    msg.timestamp = get_timestamp
    @account.route_at msg, @channel
  end
  
  def get_timestamp
    @@clickatell_timezone.parse(params[:timestamp]).utc rescue Time.now.utc
  end
  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @account = Account.find_by_id_or_name(params[:account_id])
      if !@account.nil?
        @channel = @account.channels.select{|c| 
          c.kind == 'clickatell' && 
          c.name == username && 
          c.configuration[:incoming_password] == password && 
          c.configuration[:api_id] == params[:api_id]
        }.first
      else
        false
      end
    end
  end
end
