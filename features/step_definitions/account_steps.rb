When /^an account named "([^\"]*)" exists$/ do |account_name|
  Account.create!(
    :name => account_name, 
    :password => 'secret'
  )
end
