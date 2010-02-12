class Alert < ActiveRecord::Base
  belongs_to :channel
  belongs_to :ao_message, :class_name => 'AOMessage'
end
