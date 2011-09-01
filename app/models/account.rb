require 'digest/sha2'

class Account < ActiveRecord::Base
  include Authenticable

  has_many :applications
  has_many :channels
  has_many :clickatell_channels
  has_many :qst_server_channels
  has_many :twilio_channels
  has_many :address_sources
  has_many :ao_messages
  has_many :at_messages
  has_many :custom_attributes
  has_many :logs

  serialize :app_routing_rules

  attr_accessor :password_confirmation

  validates_presence_of :name, :password
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0

  after_save :restart_channel_processes

  def self.find_by_id_or_name(id_or_name)
    account = self.find_by_id(id_or_name) if id_or_name =~ /\A\d+\Z/ or id_or_name.kind_of? Integer
    account = self.find_by_name(id_or_name) if account.nil?
    account
  end

  # Routes an AtMessage via a channel.
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

    # Fill custom attributes specified by sender
    custom_attributes = self.custom_attributes.find_by_address msg.from
    if custom_attributes
      ThreadLocalLogger << "Setting custom attributes specified for this user (#{custom_attributes.custom_attributes.to_human})"
      msg.custom_attributes.merge! custom_attributes.custom_attributes
    end

    # Set application custom attribute if the channel belongs to an application
    if via_channel.application_id
      msg.custom_attributes['application'] = applications.find_by_id(via_channel.application_id).name rescue nil
      if msg.custom_attributes['application']
        ThreadLocalLogger << "Message's application set to '#{msg.custom_attributes['application']}' because the channel belongs to it"
      end
    end

    # Assign cost
    msg.cost = via_channel.at_cost if via_channel && via_channel.at_cost.present?

    # Apply AT Rules
    at_routing_res = RulesEngine.apply(msg.rules_context, via_channel.at_rules)
    if at_routing_res.present?
      ThreadLocalLogger << "Applying channel at rules..."
      msg.merge at_routing_res
    end

    if msg.state == 'canceled'
      ThreadLocalLogger << "Message was canceled by channel at rules."
      msg.save! unless simulate

      return ThreadLocalLogger.result if simulate
      logger.info :at_message_id => msg.id, :channel_id => via_channel.id, :message => ThreadLocalLogger.result
      return
    end

    # Save mobile number information
    mob = MobileNumber.update(msg.from.mobile_number, msg.country, msg.carrier, options) if msg.from and msg.from.protocol == 'sms'

    # Intef attributes
    msg.infer_custom_attributes :mobile_number => mob

    # App Routing logic
    all_applications = applications.all
    if all_applications.empty?
      msg.save! unless simulate

      ThreadLocalLogger << "No application found for routing message"
      return ThreadLocalLogger.result if simulate
      logger.info :at_message_id => msg.id, :channel_id => via_channel.id, :message => ThreadLocalLogger.result
    elsif all_applications.length == 1
      all_applications.first.route_at(msg, via_channel, options)
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
        application = all_applications.select{|x| x.name == dest_application_name}.first
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

    logger.error :message => message
    AlertMailer.error(self, "Error in account #{self.name}", message).deliver
  end

  def queued_ao_messages_count_by_channel_id
    result = Hash.new 0
    ao_messages.joins(:channel).with_state('queued').group(:channel_id).select('channel_id, count(*) as count').each do |record|
      result[record.channel_id] = record.count.to_i
    end
    result
  end

  def logger
    @logger ||= AccountLogger.new self.id
  end

  def restart_channel_processes
    channels.each &:on_changed
  end

  def to_s
    name || id || 'unknown'
  end

  private

  def duplicated?(msg)
    return false if !msg.new_record? || msg.guid.nil?
    msg.class.exists?(['account_id = ? and guid = ?', self.id, msg.guid])
  end
end
