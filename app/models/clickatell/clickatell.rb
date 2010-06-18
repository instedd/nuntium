module Clickatell

  def self.get_credit(query_parameters)
    Clickatell.get("/http/getbalance?#{query_parameters.to_query}").body
  end
  
  def self.get_status(query_parameters)
    Clickatell.get("/http/querymsg?#{query_parameters.to_query}", :protocol => 'https').body 
  end

  def self.send_message(query_parameters)
    Clickatell.get "/http/sendmsg?#{query_parameters.to_query}", :protocol => 'https'
  end
  
  private
  
  def self.get(path, options = {:protocol => 'http'})
    RestClient.get "#{options[:protocol]}://api.clickatell.com#{path}"
  end

end
