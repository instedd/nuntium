require 'digest/sha2'

class Account < ActiveRecord::Base
  
  has_many :applications
  has_many :channels
  has_many :address_sources
  has_many :ao_messages
  has_many :at_messages
  
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
  
  def authenticate(password)
    self.password == Digest::SHA2.hexdigest(self.salt + password)
  end
  
  # Routes an ATMessage via a channel
  def route_at(msg, via_channel)
    return if duplicated? msg
    check_modified
    
    msg.account_id = self.id
    msg.timestamp ||= Time.now.utc
    if !via_channel.nil? && via_channel.class == Channel
      msg.channel = via_channel
      msg.channel_id = via_channel.id
    end
    msg.state = 'queued'
    
    # Save mobile number information
    MobileNumber.update msg.from.mobile_number, msg.country, msg.carrier if msg.from.protocol == 'sms'

    if @applications.nil?
      @applications = Application.all :conditions => ['account_id = ?', self.id]
    end
    
    if @applications.empty?
      Rails.logger.error "No application to route AT messages"  
    else
      @applications.first.route_at msg, via_channel
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
  
  def check_modified
    # Check whether the date of the account in the database is greater
    # than our date. If so, empty cached values.
    acc = Account.find_by_id(self.id, :select => :updated_at)
    if !acc.nil? && acc.updated_at > self.updated_at
      @applications = nil
    end
  end
    
end

# If many dots are sent to a validation error, an "interning empty string" error
# happens. This is a hack/fix for this.
def fix_error(msg)
  msg.gsub('.', ' ')
end
