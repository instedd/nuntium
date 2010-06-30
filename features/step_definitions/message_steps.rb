When /^the email account "([^\"]*)" receives the following email:$/ do |to, table|
  from, subject, body = table.rows_hash['From'], table.rows_hash['Subject'], table.rows_hash['Body']
  msg = AOMessage.find_by_from "mailto://#{from}"
  channel = msg.channel
  
  jobs = []
  Queues.subscribe_ao(channel){|header, job| jobs << job }
  sleep 0.3
  
  assert_equal 1, jobs.length
  assert_kind_of SendSmtpMessageJob, jobs[0]  
  assert_equal msg.id, jobs[0].message_id
  assert_equal subject, msg.subject
  assert_equal body, msg.body
end

When /^the application "([^\"]*)" sends a message with "([^\"]*)" set to "([^\"]*)"$/ do |app_name, msg_field, msg_value|
  a = Application.find_by_name app_name
  raise "Application named \"#{app_name}\" does not exist" unless a
  
  msg = AOMessage.make_unsaved msg_field => msg_value
  a.route_ao msg, 'cucumber_interface'
end

When /^the application "([^\"]*)" sends a message with "([^\"]*)" set to "([^\"]*)" and "([^\"]*)" custom attribute set to "([^\"]*)"$/ do |app_name, msg_field, msg_value, attr_name, attr_value|
  a = Application.find_by_name app_name
  raise "Application named \"#{app_name}\" does not exist" unless a
  
  msg = AOMessage.make_unsaved msg_field => msg_value
  msg.custom_attributes[attr_name] = attr_value
  a.route_ao msg, 'cucumber_interface'  
end

When /^the account "([^\"]*)" receives a message with "([^\"]*)" set to "([^\"]*)" via the "([^\"]*)" channel$/ do |acc_name, msg_field, msg_value, chan_name|
  a = Account.find_by_name acc_name
  raise "Account named \"#{acc_name}\" does not exist" unless a
  
  c = Channel.all(:conditions => ['account_id = ? AND name = ?', a.id, chan_name]).first
  raise "Channel named \"#{chan_name}\" belonging to the \"#{acc_name}\" account does not exist" unless c
  
  msg = AOMessage.make_unsaved msg_field => msg_value
  a.route_at msg, c
end

When /^the message with "([^\"]*)" set to "([^\"]*)" should have been routed to the "([^\"]*)" channel$/ do |msg_field, msg_value, chan_name|
  msg = AOMessage.send "find_by_#{msg_field}", msg_value
  raise "Message with \"#{msg_field}\" set to \"#{msg_value}\" does not exist" unless msg
  
  assert_equal chan_name, msg.channel.name
end

When /^the message with "([^\"]*)" set to "([^\"]*)" should have its carrier set to "([^\"]*)"$/ do |msg_field, msg_value, carrier_guid|
  msg = AOMessage.send "find_by_#{msg_field}", msg_value
  raise "Message with \"#{msg_field}\" set to \"#{msg_value}\" does not exist" unless msg
  
  assert_equal carrier_guid, msg.carrier
end

