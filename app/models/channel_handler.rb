# Knows what to do when an AOMessage arrives via a channel kind.
# Implementations must define a handle(msg) method.
class ChannelHandler

  def initialize(channel)
    @channel = channel
  end
  
end