class SendAoController < ApplicationAuthenticatedController

  # GET /send_ao/:account_name
  def create
    msg = AOMessage.new :account_id => @account.id
    params.each do |key, value|
      if [:from, :to, :subject, :body, :guid].include? key.to_sym
        # Normal attribute
        msg.send "#{key}=", value
      else
        # Custom attribute
        msg.custom_attributes[key] = value
      end
    end
    @application.route_ao msg, 'http'
    
    if msg.state == 'failed'
      render :text => "error: #{msg.id}"
    else
      render :text => "id: #{msg.id}"
    end
  end

end
