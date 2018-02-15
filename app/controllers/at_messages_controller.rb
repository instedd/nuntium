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

class AtMessagesController < ApplicationController
  include CustomAttributesControllerCommon

  def index
    @page = params[:page].presence || 1
    @search = params[:search]
    @previous_search = params[:previous_search]
    @page = 1 if @previous_search.present? && @previous_search != @search

    @at_messages = account.at_messages.includes(:channel, :application).order 'id DESC'
    @at_messages = @at_messages.search @search, :account => account if @search.present?
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

    redirect_to at_messages_path, :notice => %Q(AT Message was created with id #{msg.id} <a href="#{at_message_path(msg)}" target="_blank">view log</a> <a href="#{thread_at_message_path(msg)}" target="_blank">view thread</a>).html_safe
  end

  def show
    @msg = account.at_messages.find_by_id params[:id]
    @hide_title = true
    @logs = account.logs.where(:at_message_id => @msg.id).order(:created_at).all
    @kind = 'at'
    render "messages/message"
  end

  def thread
    @msg = account.at_messages.find_by_id params[:id]
    @address = @msg.from
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
    redirect_to params.to_hash
  end

  def rgviz
    render :rgviz => AtMessage, :conditions => ['at_messages.account_id = ?', account.id], :extensions => true
  end

  protected

  def get_selected_messages
    messages = account.at_messages
    if params[:at_all].to_b
      messages = messages.search params[:search], :account => account if params[:search].present?
    else
      messages = messages.where 'id IN (?)', params[:at_messages]
    end
    messages.all
  end
end
