class MobileNumber < ActiveRecord::Base
  belongs_to :country
  belongs_to :carrier
end
