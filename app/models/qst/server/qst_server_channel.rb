require 'digest/sha1'

class QstServerChannel < Channel
  include ActionView::Helpers::DateHelper

  has_many :qst_outgoing_messages, :foreign_key => 'channel_id'

  validates_presence_of :password

  configuration_accessor :password, :password_confirmation, :salt

  before_validation :reset_password, :if => lambda { password.blank? }
  before_create :hash_password
  before_update :hash_password, :if => lambda { salt.blank? }

  validate :validate_password_confirmation

  def self.title
    "QST server (local gateway)"
  end

  def handle(msg)
    outgoing = QstOutgoingMessage.new
    outgoing.channel_id = id
    outgoing.ao_message_id = msg.id
    outgoing.save
  end

  def authenticate(password)
    self.password == encode_password(decoded_salt, password)
  end

  def info
    "Last activity: " + (last_activity_at ? "#{time_ago_in_words(last_activity_at)} ago" : 'never')
  end

  private

  def reset_password
    old_configuration = configuration_was.dup
    self.password = self.password_confirmation = old_configuration[:password]
    self.salt = old_configuration[:salt]
  end

  def hash_password
    self.salt = ActiveSupport::SecureRandom.base64 8
    self.password = self.password_confirmation = encode_password(decoded_salt, password)
  end

  def decoded_salt
    Base64.decode64 salt
  end

  def encode_password(salt, password)
    Base64.encode64(Digest::SHA1.digest(salt + Iconv.conv('ucs-2le', 'utf-8', password))).strip
  end

  def validate_password_confirmation
    errors.add :password, 'does not match confirmation' if password_confirmation && password != password_confirmation
  end
end
