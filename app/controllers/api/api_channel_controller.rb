class ApiChannelController < ApiAuthenticatedController

  def index
    channels = @account.channels
    channels = channels.select{|c| c.application_id.nil? || c.application_id == @application.id}
    channels.each do |c| 
      c.account = @account
      c.application = @application if c.application_id
    end
    
    respond_to do |format|
      format.xml { render :xml => channels.to_xml(:root => 'channels', :skip_types => true) }
      format.json { render :json => channels.to_json }
    end
  end
  
  def show
    channels = @account.channels
    channels = channels.select{|c| c.application_id.nil? || c.application_id == @application.id}
    channel = channels.select{|x| x.name == params[:name]}.first
    
    return head :not_found unless channel
    
    respond_to do |format|
      format.xml { render :xml => channel.to_xml(:root => 'channels', :skip_types => true) }
      format.json { render :json => channel.to_json }
    end
  end
  
  def create
    tree = request.POST.present? ? request.POST : Hash.from_xml(request.raw_post).with_indifferent_access
    xml = tree[:channel]
    
    chan = Channel.new
    chan.account = @account
    chan.application = @application
    chan.name = xml[:name]
    chan.kind = xml[:kind]
    chan.protocol = xml[:protocol]
    chan.priority = xml[:priority]
    chan.enabled = xml[:enabled] == 'true'
    chan.direction = Channel.direction_from_text(xml[:direction])
    
    ((xml[:configuration] || {})[:property] || []).each do |property|
      chan.configuration[property[:name].to_sym] = property[:value]
    end
    
    ((xml[:restrictions] || {})[:property] || []).each do |property|
      old_value = chan.restrictions[property[:name]]
      if old_value
        if old_value.kind_of? Array
          chan.restrictions[property[:name]] << property[:value]
        else
          chan.restrictions[property[:name]] = [old_value, property[:value]]
        end
      else
        chan.restrictions[property[:name]] = property[:value]
      end
    end
    
    if chan.save
      head :ok
    else
      head :bad_request 
    end
  end

end
