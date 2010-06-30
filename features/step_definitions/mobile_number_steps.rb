Then /^the carrier associated with the number "([^\"]*)" should be "([^\"]*)"$/ do |number, carrier_name|
  mb = MobileNumber.find_by_number number
  raise "Mobile number \"#{number}\" does not exist" unless mb
  
  assert_equal carrier_name, mb.carrier.name 
end

