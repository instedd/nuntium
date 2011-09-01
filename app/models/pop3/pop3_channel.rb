require 'net/pop'

class Pop3Channel < Channel
  include CronChannel

  configuration_accessor :host, :port, :user, :password, :use_ssl, :remove_quoted_text_or_text_after_first_empty_line

  validates_presence_of :host, :user, :password
  validates_numericality_of :port, :greater_than => 0

  def self.title
    "POP3"
  end

  def self.default_protocol
    'mailto'
  end

  def check_valid_in_ui
    pop = Net::POP3.new host, port.to_i
    pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if use_ssl.to_b

    begin
      pop.start user, password
      pop.finish
    rescue => e
      errors.add_to_base(e.message)
    end
  end

  def info
    "#{user}@#{host}:#{port}"
  end

  def create_tasks
    create_task 'pop3-receive', POP3_RECEIVE_INTERVAL, ReceivePop3MessageJob.new(account_id, id)
  end

  def destroy_tasks
    drop_task 'pop3-receive'
  end
end
