class AOMessage < ActiveRecord::Base
  belongs_to :application
  validates_presence_of :application
  
  # Returns the subject and body of this message concatenated
  # with a dash, or either of them if the other is empty.
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
end

class String
  # Returns this string's protocol or nil if it doesn't have one.
  #   'sms://foobar'.protocol => 'sms'
  #   'foobar'.protocol => nil
  def protocol
    i = self.index '://'
    if i.nil?
      nil
    else
      self[0 ... i]
    end
  end
  
  # Returns this string without the protocol part.
  #   'sms://foobar'.without_protocol => 'foobar'
  #   'foobar'.without_protocol => 'foobar'
  def without_protocol
    i = self.index '://'
    if i.nil?
      self
    else
      self[i + 3 ... self.length]
    end
  end
end