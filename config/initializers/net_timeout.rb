module Net
  class HTTP
    class << self
      def new_with_config(*args)
        http = HTTP.new_without_config(*args)
        http.open_timeout = 3
        http.read_timeout = 3
        return http
      end

      alias_method :new_without_config, :new
      alias_method :new, :new_with_config
    end
  end
end
