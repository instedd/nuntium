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

When /^the "([^\"]*)" application has an AO rule that sets "([^\"]*)" to "([^\"]*)" when "([^\"]*)" "([^\"]*)" "([^\"]*)"$/ do |app_name, rule_apply_field, rule_apply_value, rule_match_field, rule_match_operator, rule_match_value|
  a = Application.find_by_name app_name
  raise "Application named \"#{app_name}\" does not exist" unless a
  
  a.ao_rules = [
      RulesEngine.rule([
        RulesEngine.matching(rule_match_field, rule_match_operator, rule_match_value)
      ],[
        RulesEngine.action(rule_apply_field, rule_apply_value)
      ])
    ]
  a.save!
end
