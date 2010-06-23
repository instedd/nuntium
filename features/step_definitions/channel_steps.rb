When /^an SMTP channel named "([^\"]*)" belongs to the "([^\"]*)" account$/ do |chan_name, account_name|
  Channel.make :smtp,
    :name => chan_name,
    :account => Account.find_by_name(account_name)
end

When /^a clickatell channel named "([^\"]*)" with "([^\"]*)" restriction set to "([^\"]*)" belongs to the "([^\"]*)" account$/ do |chan_name, restriction_name, restriction_value, account_name|
  a = Account.find_by_name account_name
  raise "Account named \"#{account_name}\" does not exist" unless a
  
  c = Channel.make :clickatell, :account => a, :name => chan_name
  c.restrictions[restriction_name] = restriction_value
  c.save!
end

