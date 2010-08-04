module ThreadLocalLogger
  def self.reset
    Thread.current[:tll] = ""
  end

  def self.<< message
    return unless Thread.current[:tll]
    Thread.current[:tll] << "\n" if Thread.current[:tll].present? 
    Thread.current[:tll] << message
  end
  
  def self.result
    Thread.current[:tll]
  end
  
  def self.destroy
    Thread.current[:tll] = nil
  end
end
