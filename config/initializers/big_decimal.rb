# TODO remove once migrated to psych 
class BigDecimal
  def to_yaml(opts={})
    YAML::quick_emit(object_id, opts) do |out|
      out.scalar("tag:nuntium.fix,2016:BigDecimal", self.to_s)
    end
  end
end

YAML.add_domain_type("nuntium.fix,2016", "BigDecimal") do |type, val|
  BigDecimal.new(val)
end
