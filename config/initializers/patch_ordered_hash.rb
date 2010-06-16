ActiveSupport::OrderedHash

# See https://rails.lighthouseapp.com/projects/8994/tickets/2123-orderedhash-to_hash-and-sort
module ActiveSupport
  class OrderedHash
    def to_yaml_type
      "!tag:yaml.org,2002:omap"
    end
    
    def to_yaml(opts = {})
      YAML.quick_emit(self, opts) do |out|
        out.seq(taguri, to_yaml_style) do |seq|
          each do |k, v|
            seq.add(k => v)
          end
        end
      end
    end
  end
  
  YAML.add_builtin_type("omap") do |type, val|
    ActiveSupport::OrderedHash[val.map(&:to_a).map(&:first)]
  end
end
