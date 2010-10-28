class ReceiveMultimodemIsmsMessageJob

  attr_accessor :account_id, :channel_id

  include CronTask::QuotedTask

  def initialize(account_id, channel_id)
    @account_id = account_id
    @channel_id = channel_id
  end

  def perform
    account = Account.find @account_id
    @channel = account.find_channel @channel_id
    @config = @channel.configuration

    url = "http://#{@config[:host]}"
    url << ":#{@config[:port]}" if @config[:port].present?
    url << "/recvmsg?"
    url << "user=#{CGI.escape(@config[:user])}&"
    url << "passwd=#{CGI.escape(@config[:password])}"

    response = RestClient.get url
    response = Hash.from_xml response.body
    notifs = response['Response']['MessageNotification']
    return unless notifs

    notifs = [notifs] unless notifs.kind_of? Array
    notifs.each do |notif|
      msg = ATMessage.new
      msg.from = notif['SenderNumber'].with_protocol @channel.protocol
      msg.body = CGI.unescape notif['Message']
      msg.channel_relative_id = notif['Message_Index']
      account.route_at msg, @channel
    end
  rescue => ex
    AccountLogger.exception_in_channel @channel, ex if @channel
  end

end
