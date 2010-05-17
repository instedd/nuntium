When /^I GET (.*)$/ do |url|
  page.driver.get url
end

When /^I POST (.+):$/ do |url, data|
  page.driver.post url, {}, :input => data
end

When /^I PUT (.+):$/ do |url, data|
  page.driver.put url, {}, :input => data
end

When /^I DELETE (.*)$/ do |url|
  page.driver.delete url
end

