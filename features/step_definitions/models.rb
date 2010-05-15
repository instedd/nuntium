When /^the following (.+) exist:$/ do |model_name, table|
  model_name = model_name.singularize
  klass = eval(model_name)
  klass.create! table.hashes
end 
