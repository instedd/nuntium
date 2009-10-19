class Application < ActiveRecord::Base
  has_many :channels
  has_many :ao_messages
  has_many :at_messages
end
