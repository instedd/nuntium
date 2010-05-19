When /^an account named "([^\"]*)" exists$/ do |account_name|
  Account.make :name => account_name, :password => 'secret'
end
