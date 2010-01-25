require 'digest/sha2'

class Application < ActiveRecord::Base
  
  has_many :channels
  has_many :ao_messages
  has_many :at_messages
  has_many :cron_tasks, :as => :parent, :dependent => :destroy
  
  serialize :configuration, Hash
  
  attr_accessor :password_confirmation
  
  validates_presence_of :name, :password, :interface
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0
  validates_inclusion_of :interface, :in => ['rss', 'qst_client']
  validate :ao_routing_test_assertions
  validate :at_routing_test_assertions
  
  before_save :hash_password 
  after_save :handle_tasks
  
  include(CronTask::CronTaskOwner)
  
  def self.find_by_id_or_name(id_or_name)
    app = self.find_by_id(id_or_name) if id_or_name =~ /\A\d+\Z/ or id_or_name.kind_of? Integer
    app = self.find_by_name(id_or_name) if app.nil?
    app
  end
  
  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end
  
  def last_at_message
    ATMessage.last(:order => :timestamp, :conditions => ['application_id = ?', self.id])
  end
  
  # Route an AOMessage
  def route(msg, via_interface)
    if @outgoing_channels.nil?
      @outgoing_channels = self.channels.all(:conditions => ['enabled = ? AND (direction = ? OR direction = ?)', true, Channel::Outgoing, Channel::Both])
    end
    
    if msg.new_record?
      # Fill msg missing fields
      msg.application_id ||= self.id
      msg.timestamp ||= Time.now.utc
    end
    
    # Find protocol of message (based on "to" field)
    protocol = msg.to.protocol
    if protocol == ''
      msg.state = 'error'
      msg.save!
      logger.ao_message_received msg, via_interface
      logger.protocol_not_found_for_ao_message msg
      return true
    end
    
    # Find channel that handles that protocol
    channels = @outgoing_channels.select {|x| x.protocol == protocol}
    
    # See if there's a custom AO routing logic 
    if !self.configuration[:ao_routing].nil? && self.configuration[:ao_routing].strip.length != 0
      # Create ao_routing function is not yet defined
      if !respond_to?(:ao_routing_function)
        instance_eval 'def ao_routing_function(app, msg, channels, via_interface, logger);' +
          'msg = MessageRouter.new(app, msg, channels, via_interface, logger);' +
          self.configuration[:ao_routing] + ';' +
          'msg.executed_action;' +
        'end;'
      end

      had_actions = ao_routing_function(self, msg, channels, via_interface, logger)
      return true if had_actions
    end
    
    # If no action triggered, or no custom logic, route to any channel
    msg = MessageRouter.new(self, msg, channels, via_interface, logger)
    msg.route_to_any_channel
    true
  rescue => e
    # Log any errors and return false
    logger.error_routing_msg msg, e
    return false
  end
  
  # Accepts an ATMessage via a channel
  def accept(msg, via_channel)
    msg.application_id = self.id
    msg.channel = via_channel if !via_channel.nil?
    msg.channel_id = via_channel.id if !via_channel.nil?
    msg.state = 'queued'
    
    # See if there's a custom AT routing logic
    if !self.configuration[:at_routing].nil? && self.configuration[:at_routing].strip.length != 0
      # Create at_routing function is not yet defined
      if !respond_to?(:at_routing_function)
        instance_eval 'def at_routing_function(msg);' + self.configuration[:at_routing] + '; end;'
      end
      
      at_routing_function msg
    end
    
    msg.save!
    
    if 'ui' == via_channel
      logger.at_message_created_via_ui msg
    else
      logger.at_message_received_via_channel msg, via_channel if !via_channel.nil?
    end
  end
  
  def logger
    if @logger.nil?
      @logger = ApplicationLogger.new(self.id)
    end
    @logger
  end
  
  def clear_password
    self.salt = nil
    self.password = nil
    self.password_confirmation = nil
    self.configuration[:cred_pass] = nil unless self.configuration.nil?
  end
  
  def set_last_at_guid(value)
    self.configuration ||= {}
    self.configuration[:last_at_guid] = value
    self.save
  end
  
  def set_last_ao_guid(value)
    self.configuration ||= {}
    self.configuration[:last_ao_guid] = value
    self.save
  end
  
  def interface_description
    case interface
    when 'rss'
      return 'rss'
    when 'qst_client'
      return 'qst_client: ' + self.configuration[:url]
    end
  end
  
  def configuration
    self[:configuration] = {} if self[:configuration].nil?
    self[:configuration]
  end

  protected
  
  # Ensures tasks for this application are correct
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
  
  private
  
  def hash_password
    if !self.salt.nil?
      return
    end
    
    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password)
  end
  
  def ao_routing_test_assertions
    has_test = (!self.configuration[:ao_routing_test].nil? and self.configuration[:ao_routing_test].strip.length > 0)
  
    if (!self.configuration[:ao_routing].nil? and self.configuration[:ao_routing].strip.length > 0) or has_test
      begin
        assert = MessageRouterAsserter.new self
        if has_test
          eval self.configuration[:ao_routing_test]
        else
          assert.simulate_dummy
        end
      rescue Exception => e
        self.errors.add(has_test ? :ao_routing_test : :ao_routing, "error: #{fix_error(e.inspect)}")
      end
    end
  end
  
  def at_routing_test_assertions
    has_test = (!self.configuration[:at_routing_test].nil? and self.configuration[:at_routing_test].strip.length > 0)
  
    if (!self.configuration[:at_routing].nil? and self.configuration[:at_routing].strip.length > 0) or has_test
      begin
        assert = MessageAccepterAsserter.new self
        if has_test
          eval self.configuration[:at_routing_test]
        else
          assert.simulate_dummy
        end
      rescue Exception => e
        self.errors.add(has_test ? :at_routing_test : :at_routing, "error: #{fix_error(e.message)}")
      end
    end
  end
  
  # If many dots are sent to a validation error, an "interning empty string" error
  # happens. This is a hack/fix for this.
  def fix_error(msg)
    msg.gsub('.', ' ')
  end
end

class MessageRouter 

  attr_reader :executed_action
  attr_reader :msg

  def initialize(application, msg, channels, via_interface, logger)
    @application = application
    @msg = msg
    @channels = channels
    @via_interface = via_interface
    @logger = logger
    @executed_action = false
  end
  
  def from; @msg.from; end
  def from=(value); @msg.from = value; end
  def to; @msg.to; end
  def to=(value); @msg.to= value; end
  def subject; @msg.subject; end
  def subject=(value); @msg.subject = value; end
  def body; @msg.body; end
  def body=(value); @msg.body = value; end
  def guid; @msg.guid; end
  def guid=(value); @msg.guid = value; end
  def timestamp; @msg.timestamp; end
  def timestamp=(value); @msg.timestamp = value; end
  
  def route_to_channel(name)
    @executed_action = true
  
    channels = @channels.select{|x| x.name == name}
    if channels.empty?
      @msg.state = 'error'
      @msg.save!
      
      @logger.ao_message_received @msg, @via_interface
      @logger.channel_not_found @msg, name
      return
    end
    
    push_message_into channels[0]
  end
  
  def route_to_any_channel(*names)
    @executed_action = true
  
    if names.length > 0
      channels = @channels.select{|x| names.include?(x.name)}
    else
      channels = @channels
    end
    
    if channels.empty?
      @msg.state = 'error'
      @msg.save!
      
      @logger.ao_message_received @msg, @via_interface
      if names.length == 0
        @logger.no_channel_found_for_ao_message @msg.to.protocol, @msg
      else
        @logger.channel_not_found @msg, names
      end
      return
    end
    
    # Select channels with less or equal metric than the other channels
    channels = channels.select{|c| channels.all?{|x| c.metric <= x.metric }}
    
    # Select a random channel to handle the message
    channel = channels[rand(channels.length)]

    push_message_into channel
  end
  
  def route_to_application(name)
    @executed_action = true
    
    @msg.application = Application.find_by_name name
    @msg.state = 'pending'
    @msg.save!

    @logger.ao_message_received @msg, @via_interface
    @logger.ao_message_routed_to_application @msg, @msg.application
    @msg.application.route @msg, {:application => @application}
  end
  
  def push_message_into(channel)
    # Save the message
    @msg.channel_id = channel.id
    @msg.state = 'queued'
    @msg.save!
    
    # Do some logging
    @logger.ao_message_received @msg, @via_interface
    @logger.ao_message_handled_by_channel @msg, channel
    
    # Let the channel handle the message
    channel.handle @msg
  end
  
  def copy
    @executed_action = true
  
    other = MessageRouter.new(@application, @msg.clone, @channels, @via_interface, @logger)
    yield other
  end
end

class MessageRouterAsserter

  attr_reader :events
  attr_reader :application

  def initialize(application)
    @application = application
    instance_eval 'def ao_routing_function(assert, msg);' +
          application.configuration[:ao_routing] + ';' + 
        'end;'
    @events = []
  end

  def routed_to_channel(*args)
    simulate args
    name = args.length == 2 ? args[1] : args[2]
    es = @events.select{|x| x[:kind] == :route_to_channel && x[:args] == name}
    prelude 'assert.routed_to_channel', args, es
  end
  
  def routed_to_any_channel(*args)
    simulate args
    
    names = []
    if args.length > 1 && args[1].class == String
      names = args[1..-1]
    elsif args.length > 2 and args[2].class == String
      names = args[2..-1]
    else
      names = nil
    end
    
    es = []
    if names.nil? || names.empty?
      es = @events.select{|x| x[:kind] == :route_to_any_channel}
    else
      es = @events.select{|x| x[:kind] == :route_to_any_channel && x[:args].all?{|y| names.include?(y)} && names.all?{|y| x[:args].include?(y)}}
    end
    
    prelude 'assert.routed_to_any_channel', args, es
  end
  
  def routed_to_application(*args)
    simulate args
    name = args.length == 2 ? args[1] : args[2]
    es = @events.select{|x| x[:kind] == :route_to_application && x[:args] == name}
    prelude 'assert.routed_to_application', args, es
  end
  
  def simulate(args)
    @events = []
    msg = AOMessage.new args[0]
    tester = MessageRouterTester.new self, msg
    ao_routing_function self, tester
    if !tester.executed_action
      tester.route_to_any_channel
    end
  rescue => e
    @application.errors.add(:ao_routing_test, "failed: #{e}")
  end
  
  def simulate_dummy
    simulate([{:from => '', :to => '', :subject => '', :body => '', :guid => '', :timestamp => Time.now.utc}, {}])
  end
  
  def prelude(name, args, es)
    if es.empty?
      assertion_failed name, args, "incorrect destination"
      return
    end
    
    if args.length > 1 && args[1].class == Hash
      check_message_transform name, args, es[0][:msg]
    end
  end
  
  def check_message_transform(name, args, original)
    expected = args[1]
    expected.each_pair do |key, value|
      actual = original.send(key)
      if actual != value
        assertion_failed name, args, "'#{key}' expected to be '#{value}' but was '#{actual}'"
      end
    end
  end
  
  def assertion_failed(name, args, message)
    @application.errors.add(:ao_routing_test, "failed in #{format_func(name, args)}: #{message}")
  end
  
  def format_func(name, args)
    name + '(' + args.map(&:inspect).join(', ') + ')'
  end

end

class MessageRouterTester

  attr_reader :executed_action

  def initialize(assert, msg)
    @assert = assert
    @msg = msg
    @executed_action = false
    @routed = false
  end
  
  def from; @msg.from; end
  def from=(value); @msg.from = value; end
  def to; @msg.to; end
  def to=(value); @msg.to= value; end
  def subject; @msg.subject; end
  def subject=(value); @msg.subject = value; end
  def body; @msg.body; end
  def body=(value); @msg.body = value; end
  def guid; @msg.guid; end
  def guid=(value); @msg.guid = value; end
  def timestamp; @msg.timestamp; end
  def timestamp=(value); @msg.timestamp = value; end
  
  def route_to_channel(name)
    check_already_routed
    @assert.events.push(:kind => :route_to_channel, :msg => @msg, :args => name)
  end
  
  def route_to_any_channel(*names)
    check_already_routed
    @assert.events.push(:kind => :route_to_any_channel, :msg => @msg, :args => names)
  end
  
  def route_to_application(name)
    check_already_routed
    @assert.events.push(:kind => :route_to_application, :msg => @msg, :args => name)
  end
  
  def check_already_routed
    @executed_action = true
    @assert.application.errors.add(:ao_routing_test, 'failed: same message routed more than once; use msg.copy') if @routed
    @routed = true
  end
  
  def copy
    @executed_action = true
    other = MessageRouterTester.new(@assert, @msg.clone)
    yield other
  end
  
  def inspect; 'Message'; end;
  def to_s; 'Message'; end;
end

class MessageAccepterAsserter

  def initialize(application)
    @application = application
    instance_eval 'def at_routing_function(msg);' +
          application.configuration[:at_routing] + ';' + 
        'end;'
  end

  def transform(original, expected, channel_name = nil)
    msg = ATMessage.new original
    if !channel_name.nil?
      msg.channel = Channel.new(:name => channel_name)
    end
    at_routing_function msg
    check_message_transform original, msg, expected 
  rescue => e
    @application.errors.add(:at_routing_test, "failed: #{e}")
  end
  
  def simulate_dummy
    transform({:from => '', :to => '', :subject => '', :body => '', :guid => '', :timestamp => Time.now.utc}, {})
  end
  
  def check_message_transform(original_hash, original, expected)
    expected.each_pair do |key, value|
      actual = original.send(key)
      if actual != value
        @application.errors.add(:ao_routing_test, "failed in assert.transform(#{original_hash.inspect}, #{expected.inspect}): '#{key}' expected to be '#{value}' but was '#{actual}'")
      end
    end
  end

end