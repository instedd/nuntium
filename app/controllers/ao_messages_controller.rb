# Copyright (C) 2009-2012, InSTEDD
#
# This file is part of Nuntium.
#
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

class AoMessagesController < ApplicationController
  include ApplicationAuthenticatedController
  include CustomAttributesControllerCommon
  include AoMessageCreateCommon

  skip_filter :check_login, :only => [:create_via_api, :get_ao]
  before_filter :authenticate, :only => [:create_via_api, :get_ao]

  def index
    @page = params[:page].presence || 1
    @search = params[:search]
    @previous_search = params[:previous_search]
    @page = 1 if @previous_search.present? && @previous_search != @search

    @ao_messages = account.ao_messages.includes(:channel, :application).order 'id DESC'
    @ao_messages = @ao_messages.search @search, :account => account if @search.present?
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

    redirect_to ao_messages_path, :notice => %Q(AO Message was created with id #{msg.id} <a href="#{ao_message_path(msg)}" target="_blank">view log</a> <a href="#{thread_ao_message_path(msg)}" target="_blank">view thread</a>).html_safe
  end

  def show
    @msg = account.ao_messages.find_by_id params[:id]
    @hide_title = true
    @logs = account.logs.where(:ao_message_id => @msg.id).order(:created_at).all
    @kind = 'ao'
    render "messages/message"
  end

  def bulk
    render "messages/bulk"
  end

  def bulk_send
    application = account.applications.find_by_id params[:application_id]
    sent = 0
    failed = 0
    AoMessage.from_json(params[:body]) do |msg|
      if application.route_ao(msg, 'user_bulk')
        sent += 1
      else
        logger.error "Error routing bulk AO message through application #{params[:application_id]}: #{msg.to_json}"
        failed += 1
      end
    end
    notice_msg = "#{sent > 0 ? sent : "No"} Application Originated #{sent == 1 ? 'message was' : 'messages were'} routed"
    notice_msg << "(#{failed} failed)" if failed > 0
    redirect_to ao_messages_path, :notice => notice_msg
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
    create_from_request
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
      messages = messages.search params[:search], :account => account if params[:search].present?
    else
      messages = messages.where 'id IN (?)', params[:ao_messages]
    end
    messages.all
  end
end
