class IpopController < ApplicationController
  before_filter :authenticate

  def index
    msg = AOMessage.new
    msg.from = params[:hp].with_protocol 'sms'
    msg.body = params[:txt]
    msg.timestamp = DateTime.strptime(params[:ts][0 .. -4], '%Y%m%d%H%M%S').to_time
    msg.channel_relative_id = params[:ts]

    @account.route_at msg, @channel

    render :text => 'OK'
  end

  def ack
    status = params[:st].to_i
    status_message = IpopChannelHandler::StatusCodes[status]

    msg = AOMessage.find_by_channel_id_and_channel_relative_id @channel.id, "#{params[:hp]}-#{params[:ts]}"
    msg.state = (status == 4 || status == 5) ? 'confirmed' : 'failed'
    msg.save!

    log_message = "Recieved status notification with status #{status} (#{status_message})"

    if status == 6
      detailed_status = params[:dst].to_i
      detailed_status_message = IpopChannelHandler::DetailedStatusCodes[detailed_status]
      log_message << ". Detailed status code #{detailed_status}: #{detailed_status_message}"

      # Insufficient credit
      if detailed_status == 13
        @channel.alert detailed_status_message
      end

      # I-POP bug
      if detailed_status == 15
        @channel.alert "Something went wrong. Please notify I-POP support."
      end
    end

    @account.logger.info :channel_id => @channel.id, :ao_message_id => msg.id,
      :message => log_message

    render :text => 'OK'
  end

  private

  def authenticate
    @account = Account.find_by_id_or_name params[:account_id]
    return head :unauthorized unless @account

    @channel = @account.find_channel params[:channel_name]
    return head :unauthorized unless @channel && @channel.kind == 'ipop'
  end
end
