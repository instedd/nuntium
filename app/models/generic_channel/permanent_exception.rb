class PermanentException < StandardError

  attr_reader :inner

  def initialize(exception)
    @inner = exception
  end
  
  def message
    "#{self.class.name}: #{@inner.message}"
  end
  
  def inspect
    "#{self.class.name}: #{@inner.inspect}"
  end
  
  def to_s
    "#{self.class.name}: #{@inner.to_s}"
  end

end
