# Knows what to do when an AOMessage arrives via a channel kind.
# Implementations must define:
# - handle(msg): to handle a message
# - check_valid: to perform error validations on channel's configuration (optional)
# - check_valid_in_ui: to perform error validations when configured from the ui, otherwise tests would become slow (optional)
# - before_save: to apply a transformation before saving it (optional)
# - update(params): copy attributes from params hash when updating (can be overriden)
# - clear_password: to clear any sensitive data from a channel before redirecting to the edit page when errors happened (optional)
# - info: public configuration info about this channel (optional)
class ChannelHandler

  def initialize(channel)
    @channel = channel
  end
  
  def update(params)
    @channel.attributes = params
  end
  
  def before_save
  end
  
  def on_enable
  end

  def on_disable
  end
  
  def on_destroy
  end
  
end