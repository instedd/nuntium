module ChannelControllerCommon

  def get_custom_attributes
    custom_attribute_names = params[:custom_attribute_name] || []
    custom_attribute_values = params[:custom_attribute_value] || [] 
    
    custom_attributes = ActiveSupport::OrderedHash.new
    
    return custom_attributes if not custom_attribute_names

    0.upto(custom_attribute_names.length).each do |i|
      name = custom_attribute_names[i]
      value = custom_attribute_values[i]
      next unless name and value 
      old = custom_attributes[name]
      if old
        if old.kind_of? Array
          old << value
        else
          custom_attributes[name] = [old, value]
        end
      else
        custom_attributes[name] = value
      end
    end
    
    custom_attributes
  end

  def get_atrules
    def safe_values(hash, key)
      h = hash[key]
      if h.nil?
        []
      else
        h.values
      end
    end
      
    atrules_hash = params[:atrules] || {}
    res = atrules_hash.values.map do |v| 
      { :matching => safe_values(v,'matching'), :action => safe_values(v,'action') } 
    end
    
    res
  end
end
