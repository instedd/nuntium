class ApiChannelController < ApiAuthenticatedController

  # GET /api/channels.:format
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
  
  # GET /api/channels/:name.:format
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
  
  # POST /api/channels.:format
  def create
    data = request.POST.present? ? request.POST : request.raw_post
    chan = nil
    respond_to do |format|
      format.xml { chan = Channel.from_xml(data) }
      format.json { chan = Channel.from_json(data) } 
    end
    chan.account = @account
    chan.application = @application
    save chan
  end
  
  # PUT /api/channels/:name.:format
  def update
    chan = @account.find_channel params[:name]
    return head :bad_request unless chan and chan.application_id == @application.id
  
    data = request.POST.present? ? request.POST : request.raw_post
    update = nil
    respond_to do |format|
      format.xml { update = Channel.from_xml(data) }
      format.json { update = Channel.from_json(data) } 
    end
    chan.merge(update)
    save chan
  end
  
  # DELETE /api/channels/:name
  def destroy
    chan = @account.find_channel params[:name]
    if chan and chan.application_id == @application.id
      chan.destroy
      head :ok
    else
      head :bad_request
    end
  end
  
  private
  
  def save(channel)
    if channel.save
      head :ok
    else
      respond_to do |format|
        format.xml { render :xml => errors_to_xml(channel.errors), :status => :bad_request }
        format.json { render :json => errors_to_json(channel.errors), :status => :bad_request } 
      end 
    end
  end
  
  def errors_to_xml(errors)
    require 'builder'
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!
    xml.error :summary => 'There were problems creating the channel' do
      errors.each do |name, value|
        xml.field :name => name, :value => value
      end
    end
    xml.target!
  end
  
  def errors_to_json(errors)
    attrs = {
      :summary => 'There were some problems',
      :fields => []
    }
    errors.each do |name, value|
      attrs[:fields] << { name => value }
    end
    attrs.to_json
  end

end
