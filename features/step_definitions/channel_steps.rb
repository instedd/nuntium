When /^an SMTP channel named "([^\"]*)" belongs to the "([^\"]*)" account$/ do |chan_name, account_name|
  Channel.make :smtp,
    :name => chan_name,
    :account => Account.find_by_name(account_name)
end

