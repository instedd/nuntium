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

class Account < ActiveRecord::Base
  include Authenticable

  has_many :applications
  has_many :channels
  has_many :clickatell_channels
  has_many :nexmo_channels
  has_many :chikka_channels
  has_many :qst_server_channels
  has_many :twilio_channels
  has_many :messenger_channels
  has_many :shujaa_channels
  has_many :address_sources
  has_many :ao_messages
  has_many :at_messages
  has_many :custom_attributes
  has_many :logs
  has_many :user_accounts
  has_many :users, :through => :user_accounts

  serialize :app_routing_rules

  attr_accessor :password_confirmation

  validates_presence_of :name, :password
  validates_uniqueness_of :name
  validates_confirmation_of :password
  validates_numericality_of :max_tries, :only_integer => true, :greater_than_or_equal_to => 0

  after_save :restart_channel_processes

  after_save :update_lifespan
  after_destroy :update_lifespan

  def self.find_by_id_or_name(id_or_name)
    account = self.find_by_id(id_or_name) if id_or_name =~ /\A\d+\Z/ or id_or_name.kind_of? Integer
    account = self.find_by_name(id_or_name) if account.nil?
    account
  end

  # Returns a pair: an account and an application.
  #  - If the name has a slash (/), it is considered to be account/application and both
  #    an account and an application will be returned if the password is that of the application.
  #  - If the name has an at (@), it is considered to be application/account and both
  #    an account and an application will be returned if the password is that of the application.
  #  - Otherwise, it is considered an account login and account, nil will be returned if succesfull.
  #  - nil, nil is returned if the login fails in any case.
  #
  # Options can be :only_application => true if only application login is accepted.
  def self.authenticate(name, password, options = {})
    account_name, app_name = name.split '/'
    app_name, account_name = name.split '@' unless app_name

    if account_name && app_name
      account = Account.find_by_name account_name
      if account
        app = account.applications.find_by_name app_name
        if app && app.authenticate(password)
          app.account = account
          return [account, app]
        end
      end
    else
      unless options[:only_application]
        account = Account.find_by_name name
        return [account, nil] if account && account.authenticate(password)
      end
    end

    [nil, nil]
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

    # Check if it's an opt-in/out/help message
    if via_channel.opt_in_enabled?
      case msg.body
      when /\s*#{via_channel.opt_help_keyword.strip}\s*/i
        return route_at_opt_help msg, via_channel, options
      when /\s*#{via_channel.opt_in_keyword.strip}\s*/i
        return route_at_opt_in msg, via_channel, options unless via_channel.whitelisted?(msg.from)
      when /\s*#{via_channel.opt_out_keyword.strip}\s*/i
        return route_at_opt_out msg, via_channel, options
      end
    end

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

  def route_at_opt_help(msg, via_channel, options = {})
    route_at_opt(msg, via_channel, 'request for help', :help, options)
  end

  def route_at_opt_in(msg, via_channel, options = {})
    route_at_opt(msg, via_channel, 'opt-in', :in, options) { via_channel.add_to_whitelist msg.from }
  end

  def route_at_opt_out(msg, via_channel, options = {})
    route_at_opt(msg, via_channel, 'opt-out', :out, options) { via_channel.remove_from_whitelist msg.from }
  end

  def route_at_opt(msg, via_channel, opt_text, opt_symbol, options = {})
    simulate = options[:simulate]

    ThreadLocalLogger << "Message is #{opt_text}."
    msg.state = 'replied'

    return ThreadLocalLogger.result if simulate

    msg.save!

    logger_result = ThreadLocalLogger.result

    yield if block_given?

    ThreadLocalLogger.reset
    ThreadLocalLogger << "Message is a reply to #{opt_text} AT message with id: #{msg.id}"
    via_channel.route_ao msg.new_reply(via_channel.send :"opt_#{opt_symbol}_message"), opt_text, options

    logger_result += "\n"
    logger_result += "AO message with id #{msg.id} created as a reply to #{opt_text}."

    logger.info :at_message_id => msg.id, :channel_id => via_channel.id, :message => logger_result
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

  def alert_emails
    users.pluck(:email)
  end

  def restart_channel_processes
    channels.each &:on_changed
  end

  def remove_user(user)
    user.user_accounts.where(account_id: id).destroy_all
    user.user_applications.where(account_id: id).destroy_all
    user.user_channels.where(account_id: id).destroy_all
  end

  def set_user_role(user, role)
    return unless ['member', 'admin'].include?(role.to_s)

    if role == 'admin'
      user.user_applications.where(account_id: id).destroy_all
      user.user_channels.where(account_id: id).destroy_all
    end

    user_account = user.user_accounts.where(account_id: id).first
    user_account.update_attributes role: role
  end

  def set_user_application_role(user, application_id, role)
    return unless ['none', 'member', 'admin'].include?(role.to_s)

    if role == 'none'
      user.user_applications.where(application_id: application_id).destroy_all
    else
      user_application = user.user_applications.where(application_id: application_id).first
      if user_application
        user_application.update_attributes role: role
      else
        user.user_applications.create! account_id: id, application_id: application_id, role: role
      end
    end

    if role != 'admin'
      user_account = user.user_accounts.where(account_id: id).first
      user_account.update_attributes role: 'member'
    end
  end

  def set_user_channel_role(user, channel_id, role)
    return unless ['none', 'member', 'admin'].include?(role.to_s)

    if role == 'none'
      user.user_channels.where(channel_id: channel_id).destroy_all
    else
      user_channel = user.user_channels.where(channel_id: channel_id).first
      if user_channel
        user_channel.update_attributes role: role
      else
        user.user_channels.create! account_id: id, channel_id: channel_id, role: role
      end
    end

    if role != 'admin'
      user_account = user.user_accounts.where(account_id: id).first
      user_account.update_attributes role: 'member'
    end
  end

  def to_s
    name || id || 'unknown'
  end

  private

  def duplicated?(msg)
    return false if !msg.new_record? || msg.guid.nil?
    msg.class.exists?(['account_id = ? and guid = ?', self.id, msg.guid])
  end

  def update_lifespan
    Telemetry::Lifespan.touch_account self
  end
end
