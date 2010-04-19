class String
  # Returns this string's protocol or '' if it doesn't have one.
  #   'sms://foobar'.protocol => 'sms'
  #   'foobar'.protocol => ''
  def protocol
    i = self.index '://'
    i.nil? ? '' : self[0 ... i]
  end
  
  # Returns this string without the protocol part.
  #   'sms://foobar'.without_protocol => 'foobar'
  #   'foobar'.without_protocol => 'foobar'
  def without_protocol
    i = self.index '://'
    i.nil? ? self : self[i + 3 ... self.length]
  end
  
  def with_protocol(protocol)
    i = self.index '://'
    if i.nil?
      protocol.to_s + '://' + self
    elsif self.protocol != protocol
      protocol.to_s + '://' + self.without_protocol
    else
      self
    end
  end
  
  alias start_with? starts_with?
  
  def integer?
    Integer(self) rescue nil
  end
  
end
