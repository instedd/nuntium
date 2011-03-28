class Integer
  def even_to_s
    even? ? 'even' : 'odd'
  end

  def as_exponential_backoff
    case self
    when 1, 2
      1
    when 3, 4, 5
      5
    when 6
      15
    else
      30
    end
  end
end
