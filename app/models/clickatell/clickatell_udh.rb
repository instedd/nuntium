# The 'udh' field of a Clickatell message. Create one with
class ClickatellUdh

  attr_accessor:reference_number
  attr_accessor :part_count
  attr_accessor :part_number
  
  # Returns a ClickatellUdh from the given string
  # or false if it's not a valid udh string.
  def self.from_string(str)
    i = 1
    while i < str.length/2
      byte = self.get_byte str, i
      if byte == 0
        i += 2
        udh = ClickatellUdh.new
        udh.reference_number = self.get_byte str, i
        i += 1
        udh.part_count = self.get_byte str, i
        i += 1
        udh.part_number = self.get_byte str, i
        return udh
      else
        i += byte + 1
      end
    end
    return false
  end
  
  def self.get_byte(str, i)
    str[i*2..i*2+1].to_i(16)
  end

end