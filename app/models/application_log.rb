class ApplicationLog < ActiveRecord::Base
  belongs_to :application
  belongs_to :channel
  belongs_to :ao_message
  belongs_to :at_message  
end
