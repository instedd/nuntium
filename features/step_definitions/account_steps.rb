When /^an account named "([^\"]*)" exists$/ do |account_name|
  Account.make :name => account_name, :password => 'secret'
end

Given /^I am authenticated as the "([^\"]*)" account$/ do |account_name|
  account = Account.find_by_name account_name
  page.driver.authorize account.name, 'secret' 
end
