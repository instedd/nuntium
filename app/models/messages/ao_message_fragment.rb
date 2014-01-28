class AoMessageFragment < ActiveRecord::Base
  validates_presence_of :account_id, :channel_id, :ao_message_id, :fragment_id, :number

  belongs_to :ao_message
end
