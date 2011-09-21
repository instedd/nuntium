module RulesEngine
  extend self

  def rule(matchings, actions, stop = false)
    return 'matchings' => matchings, 'actions' => actions, 'stop' => stop
  end

  def matching(property, operator, value)
    return 'property' => property, 'operator' => operator, 'value' => value
  end

  def action(property, value)
    return 'property' => property, 'value' => value
  end

  # matching operators supported
  OP_REGEX = 'regex'
  OP_STARTS_WITH = 'starts_with'
  OP_EQUALS = 'equals'
  OP_NOT_EQUALS = 'not_equals'

  # context is a hash with properties as keys
  # rules is a list of elements built wih RulesEngine#rule
  # a hash with actions to be taken is returned or nil if no rule matches
  def apply(context, rules)
    res = nil

    (rules || []).each do |rule|
      match_datas = matches(context, rule)
      if match_datas
        (rule['actions'] || []).each do |action|
          res = res || {}
          value = action['value']
          res[action['property']] = get_value(value, rule['matchings'], match_datas)
        end
        return res if rule['stop']
      end
    end

    res
  end

  def to_xml(xml, rules)
    (rules || []).each do |rule|
      xml.rule :stop => rule['stop'] do
        xml.matchings do
          (rule['matchings'] || []).each do |m|
            xml.matching m
          end
        end
        xml.actions do
          (rule['actions'] || []).each do |m|
            xml.action m
          end
        end
      end
    end
  end

  def from_hash(hash, format)
    if format == :json
      return hash
    elsif format == :xml
        # in :xml format we need to flatten :actions => [ { :action => { ... } } ,  { :action => { ... } } ]
        rules = []
        hash[:rule].ensure_array.each do |rule|
          matchings = rule[:matchings]
          matchings = matchings.present? ? matchings[:matching].ensure_array : []

          actions = rule[:actions]
          actions = actions.present? ? actions[:action].ensure_array : []

          rules << RulesEngine.rule(matchings, actions, rule[:stop].to_b)
        end
        return rules
    end
  end

  private

  # Collect each matching in an array if all match, else returns nil
  def matches(context, rule)
    result = []
    (rule['matchings'] || []).each do |m|
      match = matches_matching(context, m)
      return nil unless match
      result << match
    end
    result
  end

  def matches_matching(context, matching)
    at_context = context[matching['property']]
    at_context = [at_context] unless at_context.kind_of? Array
    at_matching = matching['value']
    at_context.each do |v|
      result = matches_value(v, matching['operator'], at_matching)
      return result if result
    end
    nil
  end

  def matches_value(at_context, op, at_matching)
    case op
    when OP_EQUALS
      at_context == at_matching
    when OP_NOT_EQUALS
      at_context != at_matching
    when OP_STARTS_WITH
      at_context =~ /\A\s*#{at_matching}/i
    when OP_REGEX
      Regexp.new(at_matching).match(at_context)
    else
      false
    end
  end

  # Regepx for ${...}
  VariablesRegexp = %r(\$\{(.*?)\})

  def get_value(value, matchings, match_datas)
    return value unless matchings and value.kind_of? String
    value.gsub(VariablesRegexp) do |match|
      # Remove the ${ from the beginning and the } from the end
      exp = match[2 .. -2]
      # It might be ${from.1} or ${1}
      prefix, number = exp.split('.')
      idx = nil
      if prefix and number
        # If it's ${from.1}, find first regexp rule that matches from and get the first group
        idx = matchings.find_index{|m| m['property'] == prefix and m['operator'] == OP_REGEX}
      else
        # If it's ${1}, find first regexp rule and get the first group
        idx = matchings.find_index{|m| m['operator'] == OP_REGEX}
        number = prefix
      end
      if idx and match_datas[idx]
        value = match_datas[idx][number.to_i]
      else
        match
      end
    end
  end

end
