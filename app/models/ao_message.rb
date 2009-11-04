class AOMessage < ActiveRecord::Base
  belongs_to :application
  validates_presence_of :application
  
  def subject_and_body
    if self.subject.nil? || self.subject == ''
      if self.body.nil? || self.body == ''
        ''
      else
        self.body
      end
    else
      if self.body.nil? || self.body == ''
        self.subject
      else
        self.subject + ' - ' + self.body
      end
    end
  end
  
  # Returns protocol of 'to', nil if none found.
  # Examples:
  # 1. to = 'sms://foobar' -> 'sms'
  # 2. to = 'foobar' -> nil
  def to_protocol
    self.get_protocol(self.to)
  end
  
  # Returns 'to' with the protocol stripped off
  def to_without_protocol
    self.without_protocol(self.to)
  end
  
  # Returns protocol of 'from', nil if none found.
  # Examples:
  # 1. from = 'sms://foobar' -> 'sms'
  # 2. from = 'foobar' -> nil
  def from_protocol
    self.get_protocol(self.from)
  end
  
  # Returns 'from' with the protocol stripped off
  def from_without_protocol
    self.without_protocol(self.from)
  end
  
  def get_protocol(str)
    index = str.index '://'
    if index.nil?
      nil
    else
      str[0 ... index]
    end
  end
  
  def without_protocol(str)
    index = str.index '://'
    if index.nil?
      str
    else
      str[index + 3 ... str.length]
    end
  end
end
