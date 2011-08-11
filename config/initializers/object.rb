class Object
  def to_b
    if self.class <= String
      self.downcase == 'true' || self == '1'
    elsif self.class == NilClass
      false
    else
      self
    end
  end
  
  def ensure_array
    if self.kind_of? Array
      self
    else
      [self]
    end
  end
end
