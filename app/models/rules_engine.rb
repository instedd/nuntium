module RulesEngine
  
  def rule(matchings, actions)
    return :matchings => matchings, :actions => actions
  end
   
  def matching(property, operator, value)
    return :property => property, :operator => operator, :value => value
  end
  
  def action(property, value)
    return :property => property, :value => value
  end
  
  # matching operators supported
  OP_REGEX = 'regex'
  OP_STARTS_WITH = 'starts_with'
  OP_EQUALS = 'equals'
  
  # context is a hash with properties as keys
  # rules is a list of elements built wih RulesEngine#rule
  # a hash with actions to be taken is returned or nil if no rule matches
  def apply(context, rules)
    res = nil
    
    (rules || []).each do |rule|
      if matches(context, rule)
        (rule[:actions] || []).each do |action|
          res = res || {}
          res[action[:property]] = action[:value]
        end
      end
    end
    
    res
  end
  
  private
  
  def matches(context, rule)
    (rule[:matchings] || []).all? { |m| matches_matching(context, m) }
  end
  
  def matches_matching(context, matching)
    at_context = context[matching[:property]]
    at_matching = matching[:value]

    case matching[:operator]
      when OP_EQUALS then
        return at_context == at_matching
      when OP_STARTS_WITH then
        return at_context.starts_with?(at_matching)
      when OP_REGEX then
        return !Regexp.new(at_matching).match(at_context).nil?
      else
        return false
    end  
  end
  
end