# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

require 'digest/sha2'

class Channel < ActiveRecord::Base
  include ChannelMetadata
  include ChannelSerialization

  # Channel directions
  Incoming = 1
  Outgoing = 2
  Bidirectional = Incoming + Outgoing

  belongs_to :account
  belongs_to :application

  has_many :ao_messages, ->(channel) { where(account_id: channel.account_id) }
  has_many :at_messages, ->(channel) { where(account_id: channel.account_id) }
  has_many :address_sources
  has_many :whitelists, ->(channel) { where(account_id: channel.account_id) }
  has_many :logs

  serialize :configuration, Hash
  serialize :restrictions
  serialize :ao_rules
  serialize :at_rules

  attr_accessor :throttle_opt

  validates_presence_of :name, :protocol, :kind, :account
  validates_format_of :name, :with => /\A[a-zA-Z0-9\-_]+\z/, :message => "can only contain alphanumeric characters, '_' or '-' (no spaces allowed)", :unless => proc {|c| c.name.blank?}
  validates_uniqueness_of :name, :scope => :account_id, :message => 'has already been used by another channel in the account'
  validates_inclusion_of :direction, :in => [Incoming, Outgoing, Bidirectional], :message => "must be 'incoming', 'outgoing' or 'bidirectional'"
  validates_numericality_of :throttle, :allow_nil => true, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :ao_cost, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :at_cost, :greater_than_or_equal_to => 0, :allow_nil => true
  validate :check_valid_in_ui, :if => lambda { @must_check_valid_in_ui }
  validates_presence_of :opt_in_keyword, :opt_in_message, :opt_out_keyword, :opt_out_message, :opt_help_keyword, :opt_help_message, :if => lambda { opt_in_enabled.to_b }

  scope :enabled, -> { where(:enabled => true) }
  scope :disabled, -> { where(:enabled => false) }
  scope :paused, -> { where(:paused => true) }
  scope :unpaused, -> { where(:paused => false) }
  scope :outgoing, -> { where(:direction => [Outgoing, Bidirectional]) }
  scope :incoming, -> { where(:direction => [Incoming, Bidirectional]) }
  scope :active, -> { where(:enabled => true, :paused => false) }

  after_update :reroute_messages, :if => lambda { enabled_changed? && !enabled }

  after_save :touch_application_lifespan
  after_destroy :touch_application_lifespan
  after_save :touch_account_lifespan
  after_destroy :touch_account_lifespan

  configuration_accessor :opt_in_enabled
  configuration_accessor :opt_in_keyword, :opt_in_message
  configuration_accessor :opt_out_keyword, :opt_out_message
  configuration_accessor :opt_help_keyword, :opt_help_message
  def opt_in_enabled?; opt_in_enabled.to_b; end

  def self.after_enabled(method, options = {})
    after_commit method, options.merge(:if => lambda { (previous_changes.include?('enabled') && enabled) || (previous_changes.include?('paused') && !paused) })
  end

  def self.after_changed(method, options = {})
    after_commit method, options.merge(:on => :update, :if => lambda { previous_changes.present? && !previous_changes.include?('enabled') && !previous_changes.include?('paused') && active? })
  end

  def self.after_disabled(method, options = {})
    after_commit method, options.merge(:if => lambda { (previous_changes.include?('enabled') && !enabled) || (previous_changes.include?('paused') && paused) })
  end

  def self.sort_candidate!(chans)
    chans.each{|x| x.configuration[:_p] = (x.priority || 100) + rand}
    chans.sort! do |x, y|
      result = x.configuration[:_p].floor <=> y.configuration[:_p].floor
      result = ((x.paused ? 1 : 0) <=> (y.paused ? 1 : 0)) if result == 0
      result = x.configuration[:_p] <=> y.configuration[:_p] if result == 0
      result
    end
  end

  def must_check_valid_in_ui!
    @must_check_valid_in_ui = true
  end

  def incoming?
    (direction & Incoming) != 0
  end

  def outgoing?
    (direction & Outgoing) != 0
  end

  def route_ao(msg, via_interface, options = {})
    simulate = options[:simulate]
    dont_save = options[:dont_save]

    ThreadLocalLogger << "Message routed to channel '#{name}'"

    # Assign cost
    msg.cost = ao_cost if ao_cost.present?

    # Apply AO Rules
    apply_ao_rules msg

    # Discard the message if the rules canceled the message
    if msg.state == 'canceled'
      msg.channel = self
      msg.state = 'canceled'
      msg.save! unless simulate || dont_save

      ThreadLocalLogger << "Message was canceled by channel ao rules."
      logger.info :application_id => msg.application_id, :channel_id => self.id, :ao_message_id => msg.id, :message => ThreadLocalLogger.result unless simulate
      return
    end

    # Discard the message if the 'from' and 'to' are the same
    if msg.from == msg.to
      msg.channel = self
      msg.state = 'failed'
      msg.save! unless simulate || dont_save

      ThreadLocalLogger << "Message 'from' and 'to' addresses are the same. The message will be discarded."
      logger.warning :application_id => msg.application_id, :channel_id => self.id, :ao_message_id => msg.id, :message => ThreadLocalLogger.result unless simulate
      return
    end

    # Discard message if the 'to' address is not valid
    if not msg.to.valid_address?
      msg.state = 'failed'
      msg.save! unless simulate || dont_save

      ThreadLocalLogger << "Message 'to' address is invalid. The message will be discarded."
      logger.warning :application_id => msg.application_id, :channel_id => self.id, :ao_message_id => msg.id, :message => ThreadLocalLogger.result unless simulate
      return
    end

    # Save the message
    msg.channel = self
    msg.state = 'queued'
    msg.save! unless simulate || dont_save

    # Check if we need to fragment the message
    if msg.fragment && msg.needs_fragmentation?
      return route_ao_fragments(msg, simulate, dont_save)
    end

    unless simulate
      logger.info :application_id => msg.application_id, :channel_id => self.id, :ao_message_id => msg.id, :message => ThreadLocalLogger.result

      # Handle the message
      begin
        handle msg
      rescue Exception => e
        # We use update_column here to bypass the send_delivery_ack callback
        if dont_save
          msg.state = 'failed'
        else
          msg.update_column :state, 'failed'
        end
        logger.error :application_id => msg.application_id, :channel_id => self.id, :ao_message_id => msg.id, :message => "Failed to enqueue message: #{e.class} #{e.message}"
      end

    end
  end

  def route_ao_fragments(msg, simulate, dont_save)
    fragment_id = msg.fragment_id
    fragments = msg.build_fragments

    ThreadLocalLogger << "Fragmenting into #{fragments.length} messages."

    unless simulate
      logger.info :application_id => msg.application_id, :channel_id => self.id, :ao_message_id => msg.id, :message => ThreadLocalLogger.result
    end

    fragments.each_with_index do |fragment, index|
      ThreadLocalLogger.reset
      ThreadLocalLogger << "Message created as fragment ##{index} of '#{msg.id}'"

      fragment.channel = self
      fragment.state = 'queued'
      fragment.save! unless simulate || dont_save

      unless simulate
        AoMessageFragment.create! account_id: account_id, channel_id: id, ao_message_id: fragment.id, fragment_id: fragment_id, number: index

        logger.info :application_id => fragment.application_id, :channel_id => self.id, :ao_message_id => fragment.id, :message => ThreadLocalLogger.result

        begin
          handle fragment
        rescue Exception => e
          # We use update_column here to bypass the send_delivery_ack callback
          if dont_save
            fragment.state = 'failed'
          else
            fragment.update_column :state, 'failed'
          end
          logger.error :application_id => fragment.application_id, :channel_id => self.id, :ao_message_id => fragment.id, :message => "Failed to enqueue message: #{e.class} #{e.message}"
        end
      end
    end
  end

  def apply_ao_rules(msg)
    ao_routing_res = RulesEngine.apply(msg.rules_context, self.ao_rules)
    if ao_routing_res.present?
      ThreadLocalLogger << "Applying channel ao rules..."
      msg.original = msg.merge ao_routing_res
    end
  end

  def can_route_ao?(msg)
    bypasses_restrictions?(msg) && whitelisted?(msg.to)
  end

  def bypasses_restrictions?(msg)
    # Check that each custom attribute is present in this channel's restrictions
    all_restrictions = augmented_restrictions
    msg.custom_attributes.each_multivalue do |key, values|
      channel_values = all_restrictions[key]
      next unless channel_values.present?

      channel_values = [channel_values] unless channel_values.kind_of? Array

      return false unless values.any?{|v| channel_values.include? v}
    end

    all_restrictions.each_multivalue do |key, values|
      next if values.include? ''
      return false unless msg.custom_attributes.has_key? key
    end

    return true
  end

  def whitelisted?(address)
    !opt_in_enabled? || whitelists.where(:account_id => account_id, :address => address).exists?
  end

  def add_to_whitelist(address)
    whitelists.find_or_create_by(account_id: account_id, address: address)
  end

  def remove_from_whitelist(address)
    whitelists.where(:account_id => account_id, :address => address).destroy_all
  end

  def connected=(value)
    if value
      Rails.cache.write connected_cache_key, 1, :expires_in => 2.minutes
    else
      Rails.cache.delete connected_cache_key
    end
  end

  def connected?
    !!(Rails.cache.read connected_cache_key)
  end

  def active?
    enabled? && !paused?
  end

  def self.connected(channels)
    keys = channels.select(&:has_connection?).map(&:connected_cache_key)
    hash = Rails.cache.read_multi *keys
    Hash[hash.map{|k, v| [k[/\d+/].to_i, v]}]
  end

  def configuration
    self[:configuration] ||= {}
    self[:configuration].symbolize_keys! if self[:configuration].respond_to? :symbolize_keys!
    self[:configuration]
  end

  def restrictions
    self[:restrictions] ||= ActiveSupport::OrderedHash.new
  end

  def augmented_restrictions
    restrictions
  end

  def route_at(msg)
    account.route_at msg, self
  end

  def alert(message)
    logger.error :channel_id => self.id, :message => message

    return if account.alert_emails.blank?
    AlertMailer.error(account, "Error in account #{account.name}, channel #{self.name}", message).deliver
  end

  def notify_disconnected
    alert "Warning: channel '#{name}' is disconnected"
  end

  def notify_reconnected
    alert "Notice: channel '#{name}' is now connected"
  end

  def has_connection?
    false
  end

  def direction=(value)
    if value.kind_of? String
      if value.integer?
        self[:direction] = value.to_i
      else
        self[:direction] = Channel.direction_from_text value
      end
    else
      self[:direction] = value
    end
  end

  def direction_text
    case direction
    when Incoming then 'incoming'
    when Outgoing then 'outgoing'
    when Bidirectional then 'bidirectional'
    else 'unknown'
    end
  end

  def self.direction_from_text(direction)
    case direction.downcase
    when 'incoming' then Incoming
    when 'outgoing' then Outgoing
    when 'bidirectional' then Bidirectional
    else -1
    end
  end

  def throttle_opt
    self.throttle.nil? ? 'off' : 'on'
  end

  def logger
    @logger = AccountLogger.new self.account_id
  end

  def merge(other)
    [:name, :kind, :protocol, :direction, :enabled, :priority, :configuration, :restrictions, :address, :ao_cost, :at_cost, :ao_rules, :at_rules].each do |sym|
      write_attribute sym, other.read_attribute(sym) if !other.read_attribute(sym).nil?
    end
  end

  # Perform validations that are lengthy, like checking a connection works
  def check_valid_in_ui
  end

  # Return some info about this channel
  def info
    ''
  end

  # Returns additional info for the given ao_msg in a hash, to be
  # displayed in the message view
  def more_info(ao_msg)
    {}
  end

  # Custom logic to be executed when this channel changes
  # because it's account or application changed
  def on_changed
  end

  def bind_queue
  end

  def connected_cache_key
    "channel_connected_#{id}"
  end

  def queued_ao_messages_count
    ao_messages.with_state('queued').count
  end

  def reroute_messages
    other_channels = account.channels.enabled.outgoing.where(:protocol => protocol).all
    return unless other_channels.present?

    queued_messages = ao_messages.with_state('queued').includes(:application).all
    @requeued_messages_count = queued_messages.length
    queued_messages.each { |msg| msg.application.route_ao msg, 'user' if msg.application }
  end

  def requeued_messages_count
    @requeued_messages_count || 0
  end
end
