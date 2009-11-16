class TwitterChannelStatus < ActiveRecord::Base
  belongs_to :channel
  serialize :followers, Array
end
