class ApiChannelController < ApiAuthenticatedController

  # GET /api/channels.:format
  def index
    channels = @account.channels.where('application_id = ? OR application_id IS NULL', @application.id).all
    channels.each do |c|
      c.account = @account
      c.application = @application if c.application_id
    end

    respond channels
  end

  # GET /api/channels/:name.:format
  def show
    chan = @account.channels.find_by_name params[:name]

    return head :not_found unless chan

    respond chan
  end

  # POST /api/channels.:format
  def create
    data = request.raw_post
    chan = nil
    respond_to do |format|
      format.xml { data = Hash.from_xml data; chan = Channel.from_xml data }
      format.json { data = JSON.parse data; chan = Channel.from_json data }
    end
    chan.account = @account
    if @application
      chan.application = @application
    else
      app_name = data[:application] || (data[:channel] && data[:channel][:application])
      chan.application = @account.applications.find_by_name app_name if app_name
    end
    save chan, 'creating'
  end

  # PUT /api/channels/:name.:format
  def update
    chan = @account.channels.find_by_name params[:name]

    return head :not_found unless chan
    return head :forbidden if @application && !chan.application_id

    data = request.raw_post
    update = nil
    respond_to do |format|
      format.xml { data = Hash.from_xml data; update = Channel.from_xml data }
      format.json { data = JSON.parse data; update = Channel.from_json data }
    end
    chan.merge(update)

    new_app_name = data[:application] || (data[:channel] && data[:channel][:application])
    if new_app_name
      chan.application = @account.applications.find_name new_app_name
    end
    save chan, 'updating'
  end

  # DELETE /api/channels/:name
  def destroy
    chan = @account.channels.find_by_name params[:name]

    return head :not_found unless chan
    return head :forbidden if @application && !chan.application_id

    chan.destroy
    head :ok
  end

  # GET /api/candidate/channels.:format
  def candidates
    return head :bad_request unless @application

    msg = AOMessage.from_hash params
    msg.account_id = @account.id

    channels = @application.candidate_channels_for_ao msg
    respond channels
  end

  private

  def respond(object)
    respond_to do |format|
      format.xml { render :xml => object.to_xml(:root => 'channels', :skip_types => true) }
      format.json { render :json => object.to_json }
    end
  end

  def save(channel, action)
    channel.check_valid_in_ui
    if channel.save
      respond channel
    else
      respond_to do |format|
        format.xml { render :xml => errors_to_xml(channel.errors, action), :status => :bad_request }
        format.json { render :json => errors_to_json(channel.errors, action), :status => :bad_request }
      end
    end
  end

  def errors_to_xml(errors, action)
    require 'builder'
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!
    xml.error :summary => "There were problems #{action} the channel" do
      errors.each do |name, value|
        xml.property :name => name, :value => value
      end
    end
    xml.target!
  end

  def errors_to_json(errors, action)
    attrs = {
      :summary => "There were problems #{action} the channel",
      :properties => []
    }
    errors.each do |name, value|
      attrs[:properties] << { name => value }
    end
    attrs.to_json
  end

end
