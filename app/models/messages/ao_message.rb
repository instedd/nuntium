class AOMessage < ActiveRecord::Base
  belongs_to :application
  validates_presence_of :application
  
  require 'message_common'
  include Message
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