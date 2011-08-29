class Settings
  
  ConfigFilePath = "#{::Rails.root.to_s}/config/settings.yml"
  
  if FileTest.exists?(ConfigFilePath)
    @@config = YAML.load_file(ConfigFilePath)[::Rails.env]
  else
    @@config = {}
  end
  
  class << self
    def method_missing(method_sym, *arguments, &block)
      @@config[method_sym.to_s]
    end
    
    def setting name, default
      self.class.send :define_method, name do 
        @@config[name.to_s] || default
      end
    end
  end
  
  # Settings with default value
  setting :protocol, 'https'
  setting :host_name, Socket.gethostname
  
end