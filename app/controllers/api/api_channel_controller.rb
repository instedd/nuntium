class ApiChannelController < ApiAuthenticatedController

  def index
    channels = @account.channels
    channels = channels.select{|c| c.application_id.nil? || c.application_id == @application.id}
    channels.each do |c| 
      c.account = @account
      c.application = @application if c.application_id
    end
    
    respond_to do |format|
      format.xml { render :xml => channels.to_xml(:root => 'channels') }
      format.json { render :json => channels.to_json }
    end
  end

end
