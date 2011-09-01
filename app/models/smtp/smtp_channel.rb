require 'net/smtp'

class SmtpChannel < Channel
  include GenericChannel

  configuration_accessor :host, :port, :user, :password, :use_ssl

  validates_presence_of :host
  validates_numericality_of :port, :greater_than => 0

  def self.title
    "SMTP"
  end

  def self.default_protocol
    'mailto'
  end

  def check_valid_in_ui
    smtp = Net::SMTP.new host, port.to_i
    smtp.enable_tls if use_ssl.to_b

    begin
      smtp.start 'localhost.localdomain', user, password
      smtp.finish
    rescue => e
      errors.add_to_base e.message
    end
  end

  def info
    "#{user}@#{host}:#{port}"
  end
end
