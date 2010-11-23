require 'digest/sha2'

class Application < ActiveRecord::Base
  belongs_to :account
  has_many :ao_messages
  has_many :at_messages
  has_many :address_sources
  has_many :cron_tasks, :as => :parent, :dependent => :destroy

  attr_accessor :password_confirmation

  validates_presence_of :account_id
  validates_presence_of :name, :password, :interface
  validates_confirmation_of :password
  validates_uniqueness_of :name, :scope => :account_id, :message => 'has already been used by another application in the account'
  validates_inclusion_of :interface, :in => ['rss', 'qst_client', 'http_get_callback', 'http_post_callback']
  validates_presence_of :interface_url, :unless => Proc.new {|app| app.interface == 'rss'}
  validates_presence_of :delivery_ack_url, :unless => Proc.new {|app| app.delivery_ack_method == 'none'}

  serialize :configuration, Hash
  serialize :ao_rules
  serialize :at_rules

  before_save :hash_password

  after_save :handle_tasks
  after_create :create_worker_queue
  after_save :bind_queue

  before_destroy :clear_cache
  before_destroy :delete_worker_queue
  after_save :clear_cache

  after_save :restart_channel_processes

  include(CronTask::CronTaskOwner)

  # Route an AOMessage.
  #
  # When options[:simulate] is true, a simulation is done with the following result:
  #
  # If the message was not routed:
  #  - :strategy => nil
  #  - :log => the log string
  #
  # If the message was routed using the single priority strategy:
  #  - :strategy => single_priority
  #  - :channel  => the channel, if any
  #  - :log => the log string
  #
  # If the message was routed using broadcast:
  #  - :strategy => broadcast
  #  - :messages => the list of messages (original and copies)
  #  - :logs => an array of logs for the previous messages
  def route_ao(msg, via_interface, options = {})
    simulate = options[:simulate]

    return if not simulate and duplicated?(msg)

    ThreadLocalLogger.reset
    ThreadLocalLogger << "Received via #{via_interface} interface logged in as '#{account.name}/#{name}'"

    # Fill some fields
    fill_common_message_properties msg

    # Check protocol presence
    protocol = msg.to.nil? ? '' : msg.to.protocol

    if protocol == ''
      msg.state = 'failed'
      msg.save! unless simulate

      ThreadLocalLogger << "Protocol not found in 'to' field"
      if simulate
        return {:log => ThreadLocalLogger.result}
      else
        logger.info :ao_message_id => msg.id, :message => ThreadLocalLogger.result
        return true
      end
    end

    # Save mobile number information
    mob = MobileNumber.update(msg.to.mobile_number, msg.country, msg.carrier, options) if protocol == 'sms'

    # Get the list of candidate channels
    channels = candidate_channels_for_ao msg, :mobile_number => mob

    # Exit if no candidate channel
    if channels.empty?
      msg.state = 'failed'
      msg.save! unless simulate

      ThreadLocalLogger << "No suitable channel found for routing the message"

      if simulate
        return {:log => ThreadLocalLogger.result}
      else
        logger.info :ao_message_id => msg.id, :message => ThreadLocalLogger.result
        return true
      end
    end

    # Route to the only channel if that's the case
    if channels.length == 1
      channel = channels.first
      channel.route_ao msg, via_interface, options
      if simulate
        return {:strategy => 'single_priority', :channel => channel, :log => ThreadLocalLogger.result}
      else
        return true
      end
    end

    # Or route according to a strategy
    final_strategy = strategy

    if msg.strategy && msg.strategy != final_strategy
      ThreadLocalLogger << "Strategy overwritten by message to '#{msg.strategy}'"
      final_strategy = msg.strategy
    end

    if final_strategy == 'broadcast'
      msg.state = 'broadcasted'
      msg.save! unless simulate

      logs = [ThreadLocalLogger.result] if simulate
      msgs = [msg] if simulate

      ThreadLocalLogger << "Message broadcasted"
      unless simulate
        logger.info :ao_message_id => msg.id, :message => ThreadLocalLogger.result
      end

      channels.each do |channel|
        copy = msg.clone
        copy.state = 'pending'
        copy.guid = Guid.new.to_s
        copy.parent_id = msg.id

        ThreadLocalLogger.reset

        channel.route_ao copy, via_interface, options

        msgs << copy if simulate
        logs << ThreadLocalLogger.result if simulate
      end

      if simulate
        return {:strategy => 'broadcast', :messages => msgs, :logs => logs}
      end
    else
      # Sort them first on priority, then on paused
      Channel.sort_candidate! channels

      # Save failover channels
      msg.failover_channels = channels.map(&:id)[1 .. -1].join(',')
      msg.failover_channels = nil if msg.failover_channels.empty?

      # Select the first one and route to it
      channel = channels.first
      channel.route_ao msg, via_interface, options

      if simulate
        return {:strategy => 'single_priority', :channel => channel, :log => ThreadLocalLogger.result}
      end
    end

    return true
  rescue => e
    if simulate
      return {:log => ThreadLocalLogger.result + "\n#{e}\n#{e.backtrace}"}
    else
      # Log any errors and return false
      logger.error_routing_msg msg, e
      return false
    end
  end

  def reroute_ao(msg)
    msg.tries = 0
    msg.state = 'pending'
    msg.reset_to_original
    self.route_ao msg, 're-route'
  end

  def route_at(msg, via_channel, options = {})
    simulate = options[:simulate]

    msg.application_id = self.id

    ThreadLocalLogger << "Message routed to application '#{name}'"

    # Update AddressSource if desired and if it the channel is bidirectional
    if use_address_source? and via_channel.kind_of? Channel and via_channel.direction == Channel::Bidirectional
      as = AddressSource.find_by_application_id_and_address_and_channel_id self.id, msg.from, via_channel.id
      if as.nil?
        ThreadLocalLogger << "AddressSource created with channel '#{via_channel.name}'"
        unless simulate
          AddressSource.create!(:account_id => account.id, :application_id => self.id, :address => msg.from, :channel_id => via_channel.id)
        end
      else
        ThreadLocalLogger << "AddressSource updated with channel '#{via_channel.name}'"
        as.touch unless simulate
      end
    end

    # Apply AT Rules
    at_routing_res = RulesEngine.apply(msg.rules_context, self.at_rules)
    if at_routing_res.present?
      ThreadLocalLogger << "Applying channel at rules..."
      msg.merge at_routing_res
    end

    # save the message here so we have an id for the later job
    msg.save! unless simulate

    # Check if callback interface is configured
    if self.interface == 'http_get_callback' || self.interface == 'http_post_callback'
      unless simulate
        Queues.publish_application self, SendInterfaceCallbackJob.new(msg.account_id, msg.application_id, msg.id)
      end
      if self.interface == 'http_get_callback'
        ThreadLocalLogger << "Enqueued GET callback"
      else
        ThreadLocalLogger << "Enqueued POST callback"
      end
    end

    unless simulate
      logger.info :at_message_id => msg.id, :channel_id => via_channel.id, :message => ThreadLocalLogger.result
    end
  end

  # Returns the candidate channels when routing an ao message.
  # Optimizations can be:
  #  - :mobile_number => associated to the message, so that it does not need to
  #                      be read when completing missing fields
  def candidate_channels_for_ao(msg, optimizations = {})
    # Fill some fields
    fill_common_message_properties msg

    # Find protocol of message (based on "to" field)
    protocol = msg.to.nil? ? '' : msg.to.protocol
    return [] if protocol == ''

    # Infer attributes
    msg.infer_custom_attributes optimizations

    # AO Rules
    ao_rules_res = RulesEngine.apply(msg.rules_context, self.ao_rules)
    if ao_rules_res.present?
      ThreadLocalLogger << "Applying application ao rules..."
      msg.merge ao_rules_res
    end

    # Get all outgoing enabled channels
    all_channels = account.channels

    channels = all_channels.select{|c| c.enabled && c.is_outgoing?}

    # Find channels that handle that protocol
    channels = channels.select {|x| x.protocol == protocol}

    # Filter them according to custom attributes
    channels = channels.select{|x| x.can_route_ao? msg}

    channels.sort!{|x, y| (x.priority || 100) <=> (y.priority || 100)}

    if channels.empty?
      ThreadLocalLogger << "No channels left after restrictions"
    else
      ThreadLocalLogger << "Channels left after restrictions: #{channels.map(&:name).join(', ')}"
    end

    # See if the message includes a suggested channel
    if msg.suggested_channel
      suggested_channel = channels.select{|x| x.name == msg.suggested_channel}.first
      if suggested_channel
        ThreadLocalLogger << "Suggested channel '#{msg.suggested_channel}' found in candidates"
        return [suggested_channel]
      else
        ThreadLocalLogger << "Suggested channel '#{msg.suggested_channel}' not found in candidates"
      end
    end

    # See if there is a last channel used to route an AT message with this address
    last_channel = get_last_channel msg.to, all_channels, channels
    if last_channel
      ThreadLocalLogger << "'#{last_channel.name}' selected from address sources"
      return [last_channel]
    end

    return channels
  end

  def self.find_all_by_account_id(account_id)
    apps = Rails.cache.read cache_key(account_id)
    if not apps
      apps = Application.all :conditions => ['account_id = ?', account_id]
      Rails.cache.write cache_key(account_id), apps
    end
    apps
  end

  def configuration
    self[:configuration] = {} if self[:configuration].nil?
    self[:configuration]
  end

  def is_rss
    self.interface == 'rss'
  end

  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end

  def self.configuration_accessor(name, default = nil)
    define_method(name) do
      configuration[name] || default
    end
    define_method("#{name}=") do |value|
      configuration[name] = value
    end
  end

  configuration_accessor :interface_url
  configuration_accessor :interface_user
  configuration_accessor :interface_password
  configuration_accessor :interface_custom_format
  configuration_accessor :strategy, 'single_priority'
  configuration_accessor :delivery_ack_method, 'none'
  configuration_accessor :delivery_ack_url
  configuration_accessor :delivery_ack_user
  configuration_accessor :delivery_ack_password
  configuration_accessor :last_at_guid
  configuration_accessor :last_ao_guid

  def use_address_source?
    v = configuration[:use_address_source]
    v.nil? || v.to_b
  end

  def use_address_source=(value)
    configuration[:use_address_source] = value.to_b
  end

  def strategy_description
    Application.strategy_description(strategy)
  end

  def self.strategy_description(strategy)
    case strategy
    when 'broadcast'
      'Broadcast'
    when 'single_priority'
      'Single (priority)'
    end
  end

  def delivery_ack_method_description
    case delivery_ack_method
    when 'none'
      'None'
    when 'get'
      "HTTP GET #{delivery_ack_url}"
    when 'post'
      "HTTP POST #{delivery_ack_url}"
    end
  end

  def self.delivery_ack_method_description(method)
    case method
    when 'none'
      'None'
    when 'get'
      "HTTP GET"
    when 'post'
      "HTTP POST"
    end
  end

  def interface_description
    case interface
    when 'rss'
      return 'Rss'
    when 'qst_client'
      return "QST client: #{interface_url}"
    when 'http_get_callback'
      return "HTTP GET callback: #{interface_url}"
    when 'http_post_callback'
      return "HTTP POST callback: #{interface_url}"
    end
  end

  def alert(message)
    return if account.alert_emails.blank?

    logger.error :application_id => self.id, :message => message
    AlertMailer.deliver_error account, "Error in account #{account.name}, application #{self.name}", message
  end

  def logger
    @logger ||= AccountLogger.new(self.account.id, self.id)
  end

  protected

  # Ensures tasks for this account are correct
  def handle_tasks(force = false)
    if self.interface_changed? || force
      case self.interface
        when 'qst_client'
          create_task('qst-push', QST_PUSH_INTERVAL, PushQstMessageJob.new(self.id))
          create_task('qst-pull', QST_PULL_INTERVAL, PullQstMessageJob.new(self.id))
      else
        drop_task('qst-push')
        drop_task('qst-pull')
      end
    end
  end

  def create_worker_queue
    WorkerQueue.create!(:queue_name => Queues.application_queue_name_for(self), :working_group => 'fast', :ack => true, :durable => true)
  end

  def delete_worker_queue
    wq = WorkerQueue.for_application self
    wq.destroy if wq
    true
  end

  def bind_queue
    Queues.bind_application self
    true
  end

  private

  def duplicated?(msg)
    return false if !msg.new_record? || msg.guid.nil?
    msg.class.exists?(['application_id = ? and guid = ?', self.id, msg.guid])
  end

  def fill_common_message_properties(msg)
    if msg.new_record?
      msg.account ||= self.account
      msg.application ||= self
      msg.timestamp ||= Time.now.utc
    end
  end

  def get_last_channel(address, all_channels, outgoing_channels)
    return nil unless use_address_source?
    ass = AddressSource.all :conditions => ['application_id = ? AND address = ?', self.id, address], :order => 'updated_at DESC'
    return nil if ass.empty?

    chosen_channel = nil
    address_sources_names = []

    # Return the first outgoing_channel that was used as a last channel.
    ass.each do |as|
      real = all_channels.select{|x| x.id == as.channel_id}.first
      address_sources_names << real.name if real

      if not chosen_channel
        candidate = outgoing_channels.select{|x| x.id == as.channel_id}.first
        chosen_channel = candidate if candidate
      end
    end

    ThreadLocalLogger << "Address sources are: #{address_sources_names.join(', ')}"

    chosen_channel
  end

  def hash_password
    return if self.salt.present?

    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password) if self.password
    self.password_confirmation = Digest::SHA2.hexdigest(self.salt + self.password_confirmation) if self.password_confirmation
  end

  def clear_cache
    Rails.cache.delete Application.cache_key(account_id)
    true
  end

  def restart_channel_processes
    account.restart_channel_processes
  end

  def self.cache_key(account_id)
    "account_#{account_id}_applications"
  end
end
