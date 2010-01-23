require 'drb'

class AOMessage < ActiveRecord::Base
  # need to include this to share an AOMessage across different DRb services
  include DRbUndumped
  
  belongs_to :application
  validates_presence_of :application
  
  include MessageCommon
  include MessageGetter
  include MessageState

end

# TODO: This should not be here...
class String
  # Returns this string's protocol or '' if it doesn't have one.
  #   'sms://foobar'.protocol => 'sms'
  #   'foobar'.protocol => ''
  def protocol
    i = self.index '://'
    if i.nil?
      ''
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
  
  def with_protocol(protocol)
    i = self.index '://'
    if i.nil?
      protocol.to_s + '://' + self
    elsif self.protocol != protocol
      protocol.to_s + '://' + self.without_protocol
    else
      self
    end
  end
  
end