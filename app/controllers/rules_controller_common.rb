module RulesControllerCommon

  def get_rules(param_key)
    def safe_values(hash, key)
      h = hash[key]
      h.nil? ? [] : h.values
    end

    rules_hash = params[param_key] || {}
    rules_hash = flatten rules_hash
    rules_hash.each do |rule|
      ["matchings", "actions"].each do |key|
        rule[key] = flatten rule[key] if rule[key].present?
      end
    end

    rules_hash
  end

  private

  def flatten(hash)
    res = []
    hash.keys.map(&:to_i).sort.each do |key|
      res << hash[key.to_s]
    end
    res
  end

end
