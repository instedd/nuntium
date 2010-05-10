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
    data = request.POST.present? ? request.POST : request.raw_post
    chan = nil
    respond_to do |format|
      format.xml { chan = Channel.from_xml(data) }
      format.json { chan = Channel.from_json(data) } 
    end
    chan.account = @account
    chan.application = @application
    if chan.save
      head :ok
    else
      respond_to do |format|
        format.xml { render :xml => errors_to_xml(chan.errors), :status => :bad_request }
        format.json { render :json => errors_to_json(chan.errors), :status => :bad_request } 
      end 
    end
  end
  
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
      :summary => 'There were problems creating the channel',
      :fields => []
    }
    errors.each do |name, value|
      attrs[:fields] << { name => value }
    end
    attrs.to_json
  end

end
