require 'digest/sha2'

class Account < ActiveRecord::Base

  has_many :applications
  has_many :channels
  has_many :address_sources
  has_many :ao_messages
  has_many :at_messages

  serialize :app_routing_rules

  attr_accessor :password_confirmation

  validates_presence_of :name, :password
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0

  before_save :hash_password
  after_save :restart_channel_processes

  def self.find_by_id_or_name(id_or_name)
    account = self.find_by_id(id_or_name) if id_or_name =~ /\A\d+\Z/ or id_or_name.kind_of? Integer
    account = self.find_by_name(id_or_name) if account.nil?
    account
  end

  def channels
    Channel.find_all_by_account_id id
  end

  def find_channel(id_or_name)
    channels.select{|c| c.id == id_or_name.to_i || c.name == id_or_name}.first
  end

  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end

  def applications
    Application.find_all_by_account_id id
  end

  def find_application(id_or_name)
    applications.select{|c| c.id == id_or_name.to_i || c.name == id_or_name}.first
  end

  # Routes an ATMessage via a channel.
  #
  # When options[:simulate] is true, a simulation is done and the log is returned.
  def route_at(msg, via_channel, options = {})
    simulate = options[:simulate]

    return if not simulate and duplicated?(msg)

    ThreadLocalLogger.reset
    ThreadLocalLogger << "Message received via channel '#{via_channel.name}' logged in as '#{self.name}'"

    # Fill some fields
    msg.account_id = self.id
    msg.timestamp ||= Time.now.utc
    msg.channel = via_channel
    msg.state = 'queued'

    # Discard the message if the 'from' and 'to are the same
    if msg.from == msg.to
      msg.state = 'failed'
      msg.save! unless simulate

      ThreadLocalLogger << "Message 'from' and 'to' addresses are the same. The message will be discarded."
      return ThreadLocalLogger.result if simulate
      logger.warning :at_message_id => msg.id, :channel_id => via_channel.id, :message => ThreadLocalLogger.result
      return
    end

    # Set application custom attribute if the channel belongs to an application
    if via_channel.application_id
      msg.custom_attributes['application'] = find_application(via_channel.application_id).name rescue nil
      if msg.custom_attributes['application']
        ThreadLocalLogger << "Message's application set to '#{msg.custom_attributes['application']}' because the channel belongs to it"
      end
    end

    # Apply AT Rules
    at_routing_res = RulesEngine.apply(msg.rules_context, via_channel.at_rules)
    if at_routing_res.present?
      ThreadLocalLogger << "Applying channel at rules..."
      msg.merge at_routing_res
    end

    # Save mobile number information
    mob = MobileNumber.update(msg.from.mobile_number, msg.country, msg.carrier, options) if msg.from and msg.from.protocol == 'sms'

    # Intef attributes
    msg.infer_custom_attributes :mobile_number => mob

    # App Routing logic
    if applications.empty?
      msg.save! unless simulate

      ThreadLocalLogger << "No application found for routing message"
      return ThreadLocalLogger.result if simulate
      logger.info :at_message_id => msg.id, :channel_id => via_channel.id, :message => ThreadLocalLogger.result
    elsif applications.length == 1
      applications.first.route_at(msg, via_channel, options)
      return ThreadLocalLogger.result if simulate
    else
      # if msg says which application to be used...
      dest_application_name = msg.custom_attributes['application']

      # if not, run the app_routing_rules
      if dest_application_name.nil?
        ThreadLocalLogger << "Applying account at rules..."

        app_routing_rules_res = RulesEngine.apply(msg.rules_context, self.app_routing_rules) || {}
        dest_application_name = app_routing_rules_res['application']
      end

      if dest_application_name
        application = find_application dest_application_name
        if application
          application.route_at(msg, via_channel, options)

          return ThreadLocalLogger.result if simulate
        else
          msg.save! unless simulate

          ThreadLocalLogger << "Application '#{app_routing_rules_res['application']}' does not exist"
          return ThreadLocalLogger.result if simulate
          logger.info :at_message_id => msg.id, :channel_id => via_channel.id, :message => ThreadLocalLogger.result
        end
      else
        msg.save! unless simulate

        ThreadLocalLogger << "No application was determined. Check application routing rules in account settings"
        return ThreadLocalLogger.result if simulate
        logger.info :at_message_id => msg.id, :channel_id => via_channel.id, :message => ThreadLocalLogger.result
      end
    end
  end

  def alert(message)
    return if self.alert_emails.blank?

    AlertMailer.deliver_error self, "Error in account #{self.name}", message
  end

  def logger
    @logger ||= AccountLogger.new(self.id)
  end

  def clear_password
    self.salt = nil
    self.password = nil
    self.password_confirmation = nil
  end

  def restart_channel_processes
    channels.each { |x| x.handler.on_changed }
  end

  def to_s
    name || id || 'unknown'
  end

  private

  def hash_password
    return if self.salt.present?

    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password) if self.password
    self.password_confirmation = Digest::SHA2.hexdigest(self.salt + self.password_confirmation) if self.password_confirmation
  end

  def duplicated?(msg)
    return false if !msg.new_record? || msg.guid.nil?
    msg.class.exists?(['account_id = ? and guid = ?', self.id, msg.guid])
  end

end

# If many dots are sent to a validation error, an "interning empty string" error
# happens. This is a hack/fix for this.
def fix_error(msg)
  msg.gsub('.', ' ')
end
