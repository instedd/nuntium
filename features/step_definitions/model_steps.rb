When /^the following (.+) exists?:$/ do |model_name, table|
  # Each table header denotes a field in the model. Examples:
  #  - name: model.name = ...
  #  - age: model.name = ...
  #  - configuration prop: model.configuration[prop] = ... (if configuration is a Hash)
  #  - country name: model.country = Country.find_by_name ... (otherwise)
  model_name = "#{model_name[0].chr.upcase}#{model_name[1..-1]}"
  model_name_singular = model_name.singularize
  model = eval(model_name_singular)
  
  hashes = model_name_singular == model_name ? [table.rows_hash] : table.hashes.each
  
  hashes.each do |hash|
    obj = model.new
    hash.each do |name, value|
      if name.include? ' '
        submodel_name, field = name.split(' ', 2)
        submodel_name_downcase = submodel_name.downcase
        
        if obj.send(submodel_name_downcase).kind_of? Hash
          obj.send(submodel_name_downcase).send("[]=", field.to_sym, value)
        else
          submodel_name = submodel_name.capitalize
          submodel = eval(submodel_name)
          submodel = submodel.send("find_by_#{field}", value)
          raise "#{submodel_name} with #{field} #{value} not found! :-(" unless submodel
          obj.send "#{submodel_name_downcase}=", submodel
        end
      else
        obj.send "#{name}=", value
      end
    end
    
    obj.save!
  end
end

When /^the (.+) with the (.+) "([^\"]*)" should have the following properties:$/ do |model, field, value, table|
  obj = eval("#{model.capitalize.singularize}.find_by_#{field} '#{value}'")
  assert_not_nil obj
  table.rows_hash.each do |name, value|
    actual = nil
  
    if name.include? ' '
      submodel_name, field = name.split(' ', 2)
      submodel_name_downcase = submodel_name.downcase
      
      if obj.send(submodel_name_downcase).kind_of? Hash
        actual = obj.send(submodel_name_downcase).send("[]", field.to_sym)
      else
        actual = obj.send(submodel_name_downcase).send(field)
      end
    else
      actual = obj.send(name)
    end
    
    value = value.to_i if actual.kind_of? Integer
    if value == 'nil'
      assert_nil actual
    else
      assert_equal value, actual
    end 
  end
end

When /^the (.+) with the (.+) "([^\"]*)" should not exist$/ do |model, field, value|
  assert_nil eval("#{model.capitalize.singularize}.find_by_#{field} '#{value}'")
end

