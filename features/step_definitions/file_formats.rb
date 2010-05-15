When /^I should be presented the following [x|X][m|M][l|L]:$/ do |expected_xml|
  actual_xml = Hash.from_xml(page.body)
  expected_xml = Hash.from_xml(expected_xml)
  assert_equal actual_xml, expected_xml
end

When /^I should be presented the following [j|J][s|S][o|O][n|N]:$/ do |expected_json|
  actual_json = JSON.parse(page.body)
  expected_json = JSON.parse(expected_json)
  assert_equal actual_json, expected_json
end
