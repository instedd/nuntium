module CustomAttributesControllerCommon
  def get_custom_attributes
    custom_attribute_names = params[:custom_attribute_name] || []
    custom_attribute_values = params[:custom_attribute_value] || []
    custom_attribute_options =  params[:custom_attribute_optional] || []

    custom_attributes = ActiveSupport::OrderedHash.new

    return custom_attributes if not custom_attribute_names

    0.upto(custom_attribute_names.length).each do |i|
      name = custom_attribute_names[i]
      value = custom_attribute_values[i]
      next unless name and value
      custom_attributes.store_multivalue name, value
    end

    i = 0
    j = 0
    while i < custom_attribute_options.length
      name = custom_attribute_names[j]
      next unless name

      if custom_attribute_options[i + 1].to_b
        custom_attributes.store_multivalue custom_attribute_names[j], ''
        i += 1
      end
      i += 1
      j += 1
    end

    custom_attributes
  end
end
