class ActiveSupport::Multibyte::Chars
  def self.u_unpack(string)
    begin
      string.unpack 'U*'
    rescue ArgumentError
      raise EncodingError, 'malformed UTF-8 character'
    end
  end
end
