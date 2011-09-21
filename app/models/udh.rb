class Udh
  attr_reader :length

  def initialize(str)
    @attributes = {}
    if str.nil? or str.empty?
      @length = 0
      return
    end

    @length = str[0].ord

    i = 1
    while i <= @length
      byte = str[i].ord
      if byte == 0
        i += 2
        self[0] = {}
        self[0][:reference_number] = str[i].ord
        i += 1
        self[0][:part_count] = str[i].ord
        i += 1
        self[0][:part_number] = str[i].ord
        i += 1
      else
        i += 1
        byte = str[i].ord
        i += byte + 1
      end
    end
  end

  def [](key)
    @attributes[key]
  end

  def skip(text)
    text[1 + @length .. -1]
  end

  private

  def []=(key, value)
    @attributes[key] = value
  end
end
