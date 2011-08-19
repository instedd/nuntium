# Knows what to do when an AoMessage arrives via a channel kind.
# Implementations must define:
# - handle(msg): to handle a message, typically creating a feature job to execute
# - check_valid: to perform error validations on channel's configuration (optional)
# - check_valid_in_ui: to perform error validations when configured from the ui, otherwise tests would become slow (optional)
# - before_save: to apply a transformation before saving it (optional)
# - clear_password: to clear any sensitive data from a channel before redirecting to the edit page when errors happened (optional)
# - info: public configuration info about this channel (optional)
class ChannelHandler

  def initialize(channel)
    @channel = channel
  end

  # The title of this channel. Can be overriden by subclasses.
  # By default it's the titelize name of this class' name without
  # the "ChannelHandler" part.
  def self.title
    /(.*?)ChannelHandler/.match(self.name)[1].titleize
  end

  def self.kind
    ActiveSupport::Inflector.underscore self.identifier
  end

  def self.identifier
    /(.*?)ChannelHandler/.match(self.name)[1]
  end

  def job_class
    eval("Send#{self.class.identifier}MessageJob")
  end

  def create_job(msg)
    job_class.new(@channel.account_id, @channel.id, msg.id)
  end

  def before_validation
  end

  def before_save
  end

  def on_changed
  end

  def on_create
  end

  def on_enable
  end

  def on_disable
  end

  def on_pause
  end

  def on_resume
  end

  def on_destroy
  end

  def has_connection?
    false
  end

  # Returns additional info for the given ao_msg in a hash, to be
  # displayed in the message view
  def more_info(ao_msg)
    {}
  end

  # Returns restrictions of the channel to be used to route AOs
  def restrictions
    @channel.restrictions
  end

  protected

  def check_config_not_blank(*keys)
    keys.each do |key|
      @channel.errors.add(key, "can't be blank") if @channel.configuration[key].blank?
    end
  end

  def check_config_port(options = {})
    if @channel.configuration[:port].nil?
      @channel.errors.add(:port, "can't be blank") unless options[:required] == false
    else
      port_num = @channel.configuration[:port].to_i
      if port_num <= 0
        @channel.errors.add(:port, "must be a positive number")
      end
    end
  end

end
