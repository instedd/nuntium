class PermanentException < StandardError

  attr_reader :inner

  def initialize(exception)
    @inner = exception
  end

  def message
    "#{@inner.class.name}: #{@inner.message}"
  end

  def inspect
    "#{@inner.class.name}: #{@inner.inspect}"
  end

  def to_s
    "#{@inner.class.name}: #{@inner.to_s}"
  end

end
