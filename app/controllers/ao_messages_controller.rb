class AoMessagesController < ApplicationController
  include ApplicationAuthenticatedController
  include CustomAttributesControllerCommon

  skip_filter :check_login, :only => [:create_via_api, :get_ao]
  before_filter :authenticate, :only => [:create_via_api, :get_ao]

  def index
    @page = params[:page].presence || 1
    @search = params[:search]
    @previous_search = params[:previous_search]
    @page = 1 if @previous_search.present? && @previous_search != @search

    @ao_messages = account.ao_messages.includes(:channel, :application).order 'id DESC'
    @ao_messages = @ao_messages.search @search if @search.present?
    @ao_messages = @ao_messages.paginate :page => @page, :per_page => ResultsPerPage
    @ao_messages = @ao_messages.all
  end

  def new
    @msg = AoMessage.new
    @kind = 'ao'
    render "messages/new"
  end

  def create
    msg = account.ao_messages.new params[:ao_message]
    msg.custom_attributes = get_custom_attributes
    msg.application.route_ao msg, 'user'

    redirect_to ao_messages_path, :notice => "AO Message was created with id #{msg.id} <a href=\"/message/ao/#{msg.id}\" target=\"_blank\">view log</a> <a href=\"/message/thread?address=#{msg.to}\" target=\"_blank\">view thread</a>"
  end

  def show
    @msg = account.ao_messages.find_by_id params[:id]
    @hide_title = true
    @logs = account.logs.where(:ao_message_id => @msg.id).order(:created_at).all
    @kind = 'ao'
    render "messages/message"
  end

  def thread
    @msg = account.ao_messages.find_by_id params[:id]
    @address = @msg.to
    @hide_title = true
    @page = (params[:page] || '1').to_i

    limit = @page * 5
    aos = account.ao_messages.includes(:application, :channel).where(:to => @address, :parent_id => nil).order('ao_messages.id DESC').limit(limit)
    ats = account.at_messages.includes(:application, :channel).where(:from => @address).order('at_messages.id DESC').limit(limit)

    @has_more = aos.length == limit || ats.length == limit

    @msgs = aos + ats
    @msgs.sort!{|x, y| y.created_at <=> x.created_at}

    render "messages/thread"
  end

  def mark_as_cancelled
    messages = get_selected_messages
    messages.each { |msg| msg.state = 'cancelled'; msg.save! }

    flash[:notice] = "#{messages.length} Application Originated messages #{messages.length == 1 ? 'was' : 'were'} marked as cancelled"
    params[:action] = :index
    redirect_to params
  end

  def reroute
    messages = get_selected_messages
    messages.each { |msg| msg.application.reroute_ao msg if msg.application }

    flash[:notice] = "#{messages.length} Application Originated #{messages.length == 1 ? 'message was' : 'messages were'} re-routed"
    params[:action] = :index
    redirect_to params
  end

  def simulate_route
    @msg = account.ao_messages.new params[:ao_message]
    @msg.custom_attributes = get_custom_attributes

    @result = @msg.application.route_ao @msg, 'ui', :simulate => true
    @hide_title = true
  end

  def create_via_api
    case params[:format]
    when nil
      create_single
    when 'json'
      create_many_json
    when 'xml'
      create_many_xml
    end
  end

  # GET /:account_name/:application_name/get_ao.:format
  def get_ao
    render :json => AoMessage.find_all_by_application_id_and_token(@application.id, params[:token])
  end

  def rgviz
    render :rgviz => AoMessage, :conditions => ['ao_messages.account_id = ?', account.id], :extensions => true
  end

  private

  def get_selected_messages
    messages = account.ao_messages.includes(:application)
    if params[:ao_all].to_b
      messages = messages.search params[:search] if params[:search].present?
    else
      messages = messages.where 'id IN (?)', params[:ao_messages]
    end
    messages.all
  end

  def create_single
    msg = AoMessage.from_hash params
    msg.token = params.delete(:token) || Guid.new.to_s
    route msg

    response.headers['X-Nuntium-Id'] = msg.id.to_s
    response.headers['X-Nuntium-Guid'] = msg.guid.to_s
    response.headers['X-Nuntium-Token'] = msg.token.to_s
    head :ok
  end

  def create_many_json
    create_many :from_json
  end

  def create_many_xml
    create_many :parse_xml
  end

  def create_many(method)
    token = Guid.new.to_s
    AoMessage.send(method, request.raw_post) do |msg|
      token = msg.token if msg.token
      msg.token = token
      route msg
    end
    response.headers['X-Nuntium-Token'] = token
    head :ok
  end

  def route(msg)
    msg.account_id = @account.id
    msg.token ||= Guid.new.to_s
    @application.route_ao msg, 'http'
  end
end
