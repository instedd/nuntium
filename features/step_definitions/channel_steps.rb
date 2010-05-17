When /^an SMTP channel named "([^\"]*)" belongs to the "([^\"]*)" account$/ do |chan_name, account_name|
  chan = Channel.new(
    :name => chan_name, 
    :kind => 'smtp', 
    :protocol => 'mailto', 
    :direction => Channel::Bidirectional,
    :account => Account.find_by_name(account_name)
  )
  chan.configuration = {
    :host => 'some.host',
    :port => 465,
    :user => 'some.user',
    :password => 'secret',
  }
  chan.save!
end

