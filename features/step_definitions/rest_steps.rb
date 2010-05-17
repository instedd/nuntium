When /^I PUT (.+):$/ do |url, data|
  page.driver.put url, {}, :input => data
end


When /^I DELETE (.*)$/ do |url|
  page.driver.delete url
end

