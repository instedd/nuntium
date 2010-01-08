class DRbProcess < ActiveRecord::Base
  belongs_to :application
  belongs_to :channel
  
end
