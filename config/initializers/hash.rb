class Hash

  # If the old value of the key does not exist:
  #  - this is equivalent to hash[key] = value
  # If the old value exists:
  #  - If it's an array, the value is appended to it
  #  - Else, the new value will be an array containing the previous and new values.
  def store_multivalue(key, value)
    old = self[key]
    if old
      if old.kind_of? Array
        old << value
      else
        self[key] = [old, value]
      end
    else
      self[key] = value
    end
  end
  
  # Same as each, but every yielded value will be an array
  def each_multivalue
    each do |key, values|
      values = [values] unless values.kind_of? Array
      yield key, values
    end
  end

end
