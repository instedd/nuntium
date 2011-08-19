# coding: utf-8

class DtacChannel < Channel
  include GenericChannel

  configuration_accessor :user, :password

  validates_presence_of :user, :password

  def self.title
    "DTAC"
  end

  def info
    user
  end

=begin
  Dtac errors are mapped as fatal, temporary, message or unexpected.
  These categories are used to trap exceptions for SendMessageJob.
=end
  DTAC_ERRORS = {
    -1    => { :kind => :temporary, :description => 'System is not ready: System Error now, please try to post message to DTAC later'},
    -101  => { :kind => :fatal, :description => 'Invalid CP: This Corporate cannot be found on DTAC'},
    -102 => { :kind => :fatal, :description => 'Invalid CP Status: Your service status is not available'},
    -103 => { :kind => :fatal, :description => 'Quota Limit exceed: You cannot send message over than quota limit'},
    -104 => { :kind => :message, :description => 'Duplicate RefNo: Message with this "RefNo" has been sent'},
    -105 => { :kind => :fatal, :description => 'Your account is expired'},
    -106 => { :kind => :message, :description => 'MsnList length limit exceed: Number of MsnList is over than 1000'},
    -107 => { :kind => :message, :description => 'Sno length limit exceed: Parameter "Sno" is over than 10 digits'},
    -108 => { :kind => :message, :description => 'Message is null: Parameter "Msg" is null'},
    -109 => { :kind => :message, :description => 'Invalid Msn: Invalid Msn format'},
    -110 => { :kind => :fatal, :description => 'Invalid User / Invalid Password: Not valid User or Password'},
    -111 => { :kind => :message, :description => 'Message length exceed 1000 characters: The length of parameter "Msg" is over than 1000 characters'},
    -112 => { :kind => :message, :description => 'Invalid Sender: Invalid Sender, this sender does not existed or inactive'},
    -113 => { :kind => :message, :description => 'Sender Expire: Invalid Sender, this sender is already expired'},
    -114 => { :kind => :message, :description => 'Encoding is null: Parameter "Encoding" is null'},
    -115 => { :kind => :message, :description => 'MsgType is null: Parameter "MsgType" is null'},
    -116 => { :kind => :message, :description => 'TimeStamp is null: Parameter “TimeStamp” is null'},
    -117 => { :kind => :message, :description => 'Invalid Concat'},
    -118 => { :kind => :message, :description => 'Reference Number is null: Parameter "Reference Number" is null'},
    -119 => { :kind => :message, :description => 'Reference Number length exceed 15 digit'},
    -120 => { :kind => :message, :description => 'Invalid Encoding'},
    -121 => { :kind => :message, :description => 'Invalid UserHeader'},
    -122 => { :kind => :message, :description => 'Eng message length can not be longer than 160 characters'},
    -123 => { :kind => :message, :description => 'Thai message length can not be longer than 70 characters'},
    -124 => { :kind => :message, :description => 'Hexadecimal message length can not be longer than 280 characters'},
    -125 => { :kind => :message, :description => 'Eng message length can not be longer than 153 characters'},
    -126 => { :kind => :message, :description => 'Thai message length can not be longer than 67 characters'},
    -127 => { :kind => :message, :description => 'Hexadecimal message length can not longer than 268 characters'},
    -128 => { :kind => :message, :description => 'Invalid TimeStamp'},
    -129 => { :kind => :message, :description => 'Invalid Validperiod'},
    -131 => { :kind => :message, :description => 'Invalid msg type'},
    -132 => { :kind => :message, :description => 'Maximum Valid Period is 12 hrs. or 43200 second'},
    -133 => { :kind => :message, :description => 'Minimum Valid Period is 10 minute. or 600 second'},
    -134 => { :kind => :fatal, :description => 'User is null: Parameter "User" is null'},
    -135 => { :kind => :fatal, :description => 'Password is null: Parameter "Password" is null'},
    -136 => { :kind => :message, :description => 'Sno is not number: Parameter "Sno" is not a number'},
    -501 => { :kind => :temporary, :description => 'Database is not ready. Please try to post again later.'}
  }
end
