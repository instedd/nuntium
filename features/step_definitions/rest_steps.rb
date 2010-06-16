When /^I GET (.*)$/ do |url|
  page.driver.get url
end

When /^I POST XML (.+):$/ do |url, data|
  page.driver.post url, {}, :input => data, 'CONTENT_TYPE' => 'application/xml'
end

When /^I POST JSON (.+):$/ do |url, data|
  page.driver.post url, {}, :input => data, 'CONTENT_TYPE' => 'application/json'
end

When /^I PUT XML (.+):$/ do |url, data|
  page.driver.put url, {}, :input => data, 'CONTENT_TYPE' => 'application/xml'
end

When /^I PUT JSON (.+):$/ do |url, data|
  page.driver.put url, {}, :input => data, 'CONTENT_TYPE' => 'application/json'
end

When /^I DELETE (.*)$/ do |url|
  page.driver.delete url
end

