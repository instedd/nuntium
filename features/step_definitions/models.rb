When /^the following (.+) exist:$/ do |model_name, table|
  # Each table header denotes a field in the model. Examples:
  #  - name: model.name = ...
  #  - age: model.name = ...
  #  - country name: model.country = Country.find_by_name ...  

  model_name = model_name.singularize.capitalize
  model = eval(model_name)
  
  table.hashes.each do |hash|
    attrs = {}
    hash.each do |name, value|
      if name.include? ' '
        submodel_name, field = name.split(' ', 2)
        submodel_name = submodel_name.capitalize
        submodel = eval(submodel_name)
        submodel = submodel.send("find_by_#{field}", value)
        raise "#{submodel_name} with #{field} #{value} not found! :-(" unless submodel
        attrs[submodel_name.downcase] = submodel
      else
        attrs[name] = value
      end
    end
    model.create! attrs
  end
end
