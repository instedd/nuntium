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

Then /^the message with "([^\"]*)" set to "([^\"]*)" should have been routed to the "([^\"]*)" channel$/ do |msg_field, msg_value, chan_name|
  msg = AOMessage.send "find_by_#{msg_field}", msg_value
  raise "Message with \"#{msg_field}\" set to \"#{msg_value}\" does not exist" unless msg
  
  assert_equal chan_name, msg.channel.name
end

