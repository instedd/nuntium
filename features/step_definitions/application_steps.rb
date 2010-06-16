When /^an application named "([^\"]*)" belongs to the "([^\"]*)" account$/ do |app_name, account_name|
  Application.make :rss, 
    :name => app_name,
    :password => 'secret', 
    :account => Account.find_by_name(account_name)
end

Given /^I am authenticated as the "([^\"]*)" application$/ do |app_name|
  app = Application.find_by_name app_name
  page.driver.authorize "#{app.account.name}/#{app.name}", 'secret' 
end

