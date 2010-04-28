module RulesControllerCommon
  
  def get_rules(param_key)
    def safe_values(hash, key)
      h = hash[key]
      h.nil? ? [] : h.values
    end
      
    rules_hash = params[param_key] || {}
    res = rules_hash.values.map do |v| 
      { :matching => safe_values(v,'matching'), :action => safe_values(v,'action') } 
    end
    
    res
  end
  
end