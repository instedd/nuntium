module CustomAttributesControllerCommon

  def get_custom_attributes
    custom_attribute_names = params[:custom_attribute_name] || []
    custom_attribute_values = params[:custom_attribute_value] || [] 
    
    custom_attributes = ActiveSupport::OrderedHash.new
    
    return custom_attributes if not custom_attribute_names

    0.upto(custom_attribute_names.length).each do |i|
      name = custom_attribute_names[i]
      value = custom_attribute_values[i]
      next unless name and value
      custom_attributes.store_multivalue name, value
    end
    
    custom_attributes
  end

end
