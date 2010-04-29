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
  
  # Routes an ATMessage via a channel
  def route_at(msg, via_channel)
    return if duplicated? msg
    
    msg.account_id = self.id
    msg.timestamp ||= Time.now.utc
    msg.channel = via_channel if via_channel.kind_of? Channel
    msg.state = 'queued'
    
    # Apply AT Rules
    if via_channel.kind_of? Channel
      at_routing_res = RulesEngine.apply(msg.rules_context, via_channel.at_rules)
      msg.merge at_routing_res
    end
    
    # Save mobile number information
    MobileNumber.update msg.from.mobile_number, msg.country, msg.carrier if msg.from.protocol == 'sms'

    # App Routing logic
    if applications.empty?
      msg.save!
      logger.no_application_to_route msg
    elsif applications.length == 1
      applications.first.route_at msg, via_channel
    else
      # if msg says which application to be used ...
      dest_application_name = msg.custom_attributes['application']
      
      # if not, run the app_routing_rules
      if dest_application_name.nil?
        app_routing_rules_res = RulesEngine.apply(msg.rules_context, self.app_routing_rules) || {}
        dest_application_name = app_routing_rules_res['application']
      end
      
      if !dest_application_name.nil?  
        application = find_application dest_application_name
        unless application.nil?
          application.route_at msg, via_channel
        else
          msg.save!
          logger.application_not_found msg, app_routing_rules_res['application']
        end
      else
        msg.save!
        logger.no_application_was_determined msg
      end
    end
  end
  
  def alert(message)
    # TODO send an email somehow...
    Rails.logger.info "Received alert for account #{self.name}: #{message}"
    logger.error message.to_s
  end
  
  def logger
    if @logger.nil?
      @logger = AccountLogger.new(self.id)
    end
    @logger
  end
  
  def clear_password
    self.salt = nil
    self.password = nil
    self.password_confirmation = nil
  end
  
  def to_s
    name || id || 'unknown'
  end
  
  private
  
  def hash_password
    return if self.salt.present?
    
    self.salt = ActiveSupport::SecureRandom.base64(8)
    self.password = Digest::SHA2.hexdigest(self.salt + self.password)
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
