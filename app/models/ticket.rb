class Ticket < ActiveRecord::Base

  validates_inclusion_of :status, :in => ['pending', 'complete']
  serialize :data, Hash
  validates_uniqueness_of :code

  def self.checkout(data = nil)
    ticket = Ticket.new({
      :code => Ticket.generate_random_code,
      :secret_key => Guid.new.to_s,
      :expiration => Ticket.get_expiration,
      :data => data,
      :status => 'pending'
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
  
  def self.complete(code, data = {})
    ticket = Ticket.find_by_code_and_status code, 'pending'
    
    raise "Invalid code" if ticket.nil?
    ticket.data = (ticket.data || {}).merge! data
    ticket.status = 'complete'

    ticket.save!
    ticket
  end
  
  def self.remove_expired
    Ticket.delete_all ['expiration < ?', Time.now.utc]
  end

  def to_json
    { :code => code , :secret_key => secret_key, :data => (data || {}) }.to_json
  end

private

  def self.format_code number
    sprintf "%04d", number
  end

  def self.generate_random_code
    code = rand(9999)    
    until Ticket.find_by_code(format_code(code)).nil? do 
      code = (code + 1) % 10000
    end    
    format_code(code)
  end
  
  def self.get_expiration
    Time.now.utc + 1.day
  end
end
