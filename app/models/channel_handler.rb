# Knows what to do when an AOMessage arrives via a channel kind.
# Implementations must define:
# - handle(msg): to handle a message
# - check_valid: to perform error validations on channel's configuration (optional)
# - before_save: to apply a transformation before saving it (optional)
# - update(params): copy attributes from params hash when updating (can be overriden)
class ChannelHandler

  def initialize(channel)
    @channel = channel
  end
  
  def update(params)
    @channel.attributes = params
  end
  
end