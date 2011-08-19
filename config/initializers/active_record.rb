class ActiveRecord::Base
  def self.configuration_accessor(*names)
    options = names.extract_options!
    default = options[:default]

    names.each do |name|
      define_method(name) do
        configuration[name] || default
      end
      define_method("#{name}=") do |value|
        configuration_will_change!
        configuration[name] = value
      end
    end
  end
end
