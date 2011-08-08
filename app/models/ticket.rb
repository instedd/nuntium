class Ticket < ActiveRecord::Base

  def self.checkout(*params)
    ticket = Ticket.new({
      :code => Ticket.generate_random_code,
      :secret_key => Guid.new,
      :expiration => Ticket.get_expiration
    })
    
    ticket.save!    
    ticket
  end
  
  def self.keep_alive(code, secret_key)
    ticket = Ticket.find_by_code_and_secret_key code, secret_key
    raise "Invalid code or secret key" if ticket.nil?
    
    ticket.expiration = Ticket.get_expiration
    
    ticket
  end
  
  def self.remove_expired
    Ticket.delete_all ['expiration < ?', Time.now.utc]
  end

private

  def self.generate_random_code
    rand 9999
  end
  
  def self.get_expiration
    Time.now.utc + 1.day
  end
end
