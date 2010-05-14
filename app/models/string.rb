class String
  alias start_with? starts_with?

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
  
  # Adds the given protocol to the string, or replaces
  # it if it already has one.
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
  
  # Does this string represent an integer?
  def integer?
    Integer(self) rescue nil
  end
  
  # Returns the mobile number represented in this string
  # (no protocol and + prefix removed)
  def mobile_number
    num = self.without_protocol
    num = num[1..-1] if num[0].chr == '+'
    num 
  end
  
  # Returns true if this string is a two hex chars sequence
  def is_hex?
    self =~ /[0-9a-fA-F]{4}+/
  end
  
  # Converts each pair of characters into it's hexadecimal char
  # equivalent. For example:
  # "0502".hex_to_bytes # => "\005\002" 
  def hex_to_bytes
    self.scan(/../).map{|x| x.to_i(16).chr}.join
  end
  
end
