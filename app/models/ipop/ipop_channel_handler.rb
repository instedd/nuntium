class IpopChannelHandler < GenericChannelHandler
  def self.title
    "I-POP"
  end

  def check_valid
    @channel.errors.add(:address, "can't be blank") if @channel.address.blank?
    check_config_not_blank :mt_post_url, :bid, :cid
  end

  StatusCodes = {
    3 => 'Failure',
    4 => 'Operator SMSC',
    5 => 'Successful billing or Mobile Acknowledgement',
    6 => 'Unsuccessful billing or Failed Mobile Acknowledgement'
  }

  DetailedStatusCodes = {
    10 => 'Invalid Number: Invalid subscriber - recycled msisdn',
    11 => 'Temporary Block - Operator temporary suspend',
    12 => 'Permanent Block: Blocked by the operator - pre/post-paid preference ban',
    13 => 'Insufficient Credit: Insufficient prepaid balance',
    14 => 'Retry Exhausted: other errors - gateway timeout',
    15 => 'Unkown 3rd Party Error',
    16 => 'MSISDN Not Registered at Op - MSISDN Blackout Period',
    18 => 'Reserved for future use'
  }
end
