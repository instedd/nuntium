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
    index = self.to.index '://'
    if index.nil?
      nil
    else
      self.to[0 ... index]
    end
  end
  
  # Returns 'to' with the protocol stripped off
  def to_without_protocol
    index = self.to.index '://'
    if index.nil?
      self.to
    else
      self.to[index + 3 ... self.to.length]
    end
  end
end
