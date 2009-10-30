class QstChannelHandler < ChannelHandler
  def handle(msg)
    outgoing = QSTOutgoingMessage.new
    outgoing.channel_id = @channel.id
    outgoing.guid = msg.guid
    outgoing.save
  end
end