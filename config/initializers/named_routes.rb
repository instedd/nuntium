class NamedRoutes
  include Singleton
  include ActionController::UrlWriter
  
  def self.default_url_options
    {
      :protocol => Settings.protocol,
      :host => Settings.host_name
    }
  end
  
  def self.method_missing(method_sym, *arguments, &block)
    self.instance.send method_sym, arguments, block
  end
  
end