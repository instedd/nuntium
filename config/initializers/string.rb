class String
  AddressRegexp = %r(^(.*?)://(.*?)$)
  SmsRegexp = /^(\+)?\d+$/
  EmailRegexp = /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i

  alias start_with? starts_with?

  # Returns this string's protocol or '' if it doesn't have one.
  #   'sms://foobar'.protocol => 'sms'
  #   'foobar'.protocol => ''
  def protocol
    self =~ AddressRegexp ? $1 : ''
  end

  # Returns this string without the protocol part.
  #   'sms://foobar'.without_protocol => 'foobar'
  #   'foobar'.without_protocol => 'foobar'
  def without_protocol
    self =~ AddressRegexp ? $2 : self
  end

  # Adds the given protocol to the string, or replaces
  # it if it already has one.
  def with_protocol(protocol)
    "#{protocol}://#{self =~ AddressRegexp ? $2 : self}"
  end

  # Returns a two element array with the protocol and
  # address of this string.
  def protocol_and_address
    self =~ AddressRegexp ? [$1, $2] : ['', self]
  end

  # Does this string represent an integer?
  def integer?
    Integer(self) rescue nil
  end

  # Returns the mobile number represented in this string
  # (no protocol and + prefix removed)
  def mobile_number
    num = self.without_protocol
    num = num[1..-1] if num.length > 0 and num[0].chr == '+'
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

  # Determines if this string is a valid address.
  # The validity of an address depends on its protocol.
  # Sms addresses can only have numbers and an optional + in front of them.
  # Email addresses can only be, well, email addresses.
  def valid_address?
    protocol, address = protocol_and_address
    case protocol
    when 'sms':
      !!(address =~ SmsRegexp)
    when 'mailto'
      !!(address =~ EmailRegexp)
    else
      true
    end
  end

end
