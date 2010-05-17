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

