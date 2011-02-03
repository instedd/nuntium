class Time
  def milliseconds
    ((to_f - to_f.floor) * 1000).floor
  end
end
