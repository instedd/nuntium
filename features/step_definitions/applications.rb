When /^an application named (.+) belongs to the (.+) account$/ do |app_name, account_name|
  Application.create!( 
    :name => app_name,
    :interface => 'rss',
    :password => 'secret', 
    :account => Account.find_by_name(account_name)
  )
end

