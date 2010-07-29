When /^the carrier associated with the number "([^\"]*)" should be "([^\"]*)"$/ do |number, carrier_name|
  mb = MobileNumber.find_by_number number
  raise "Mobile number \"#{number}\" does not exist" unless mb
  
  assert_equal carrier_name, mb.carrier.name 
end

When /^the number "([^\"]*)" is associated to the "([^\"]*)" carrier$/ do |number, carrier_name|
  c = Carrier.find_by_name carrier_name
  raise "Carrier named \"#{carrier_name}\" does not exist" unless c
  
  MobileNumber.create! :number => number, :carrier => c 
end

