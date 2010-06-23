When /^an "([^\"]*)" channel named "([^\"]*)" belongs to the "([^\"]*)" account$/ do |chan_kind, chan_name, account_name|
  Channel.make chan_kind.to_sym,
    :name => chan_name,
    :account => Account.find_by_name(account_name)
end

When /^a "([^\"]*)" channel named "([^\"]*)" with "([^\"]*)" restriction set to "([^\"]*)" belongs to the "([^\"]*)" account$/ do |chan_kind, chan_name, restriction_name, restriction_value, account_name|
  a = Account.find_by_name account_name
  raise "Account named \"#{account_name}\" does not exist" unless a
  
  c = Channel.make chan_kind.to_sym, :account => a, :name => chan_name
  c.restrictions[restriction_name] = restriction_value
  c.save!
end

Given /^a "([^\"]*)" channel named "([^\"]*)" with "([^\"]*)" set to "([^\"]*)" belongs to the "([^\"]*)" account$/ do |chan_kind, chan_name, field_name, field_value, account_name|
  a = Account.find_by_name account_name
  raise "Account named \"#{account_name}\" does not exist" unless a

  Channel.make chan_kind.to_sym, :account => a, :name => chan_name, field_name => field_value
end

