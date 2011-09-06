class AtMessagesController < ApplicationController
  include CustomAttributesControllerCommon

  def index
    @page = params[:page].presence || 1
    @search = params[:search]
    @previous_search = params[:previous_search]
    @page = 1 if @previous_search.present? && @previous_search != @search

    @at_messages = account.at_messages.includes(:channel, :application).order 'id DESC'
    @at_messages = @at_messages.search @search if @search.present?
    @at_messages = @at_messages.paginate :page => @page, :per_page => ResultsPerPage
    @at_messages = @at_messages.all
  end

  def new
    @msg = AtMessage.new
    @kind = 'at'
    render "messages/new"
  end

  def create
    msg = account.at_messages.new params[:at_message]
    msg.custom_attributes = get_custom_attributes
    account.route_at msg, msg.channel

    redirect_to at_messages_path, :notice => "AT Message was created with id #{msg.id} <a href=\"/message/at/#{msg.id}\" target=\"_blank\">view log</a> <a href=\"/message/thread?address=#{msg.from}\" target=\"_blank\">view thread</a>"
  end

  def show
    @msg = account.at_messages.find_by_id params[:id]
    @hide_title = true
    @logs = account.logs.where(:at_message_id => @msg.id).order(:created_at).all
    @kind = 'at'
    render "messages/message"
  end

  def simulate_route
    @msg = account.at_messages.new params[:at_message]
    @msg.custom_attributes = get_custom_attributes

    @log = account.route_at @msg, @msg.channel, :simulate => true
    @hide_title = true
  end

  def mark_as_cancelled
    messages = get_selected_messages
    messages.each { |msg| msg.state = 'cancelled'; msg.save! }

    flash[:notice] = "#{messages.length} Application Terminated messages #{messages.length == 1 ? 'was' : 'were'} marked as cancelled"
    params[:action] = :index
    redirect_to params
  end

  def rgviz
    render :rgviz => AtMessage, :conditions => ['at_messages.account_id = ?', account.id], :extensions => true
  end

  protected

  def get_selected_messages
    messages = account.at_messages
    if params[:at_all].to_b
      messages = messages.search params[:search] if params[:search].present?
    else
      messages = messages.where 'id IN (?)', params[:at_messages]
    end
    messages.all
  end
end
