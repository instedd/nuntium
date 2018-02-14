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

require 'rss/1.0'
require 'rss/2.0'
require 'nokogiri'

class RssController < ApplicationController
  include ApplicationAuthenticatedController

  skip_before_action :check_login
  before_action :authenticate

  # GET /:account_name/:application_name/rss
  def index
    last_modified = request.env['HTTP_IF_MODIFIED_SINCE']
    etag = request.env['HTTP_IF_NONE_MATCH']

    @at_messages = @account.at_messages.order 'timestamp DESC'
    @at_messages = @at_messages.where :application_id => @application.id
    @at_messages = @at_messages.with_state 'queued', 'delivered'
    @at_messages = @at_messages.where 'timestamp > ?', DateTime.parse(last_modified) if last_modified
    @at_messages = @at_messages.all

    return head :not_modified if @at_messages.empty?

    if !etag.nil?
      # If there's an etag, find the matching message and collect up to it in temp_messages
      temp_messages = []
      @at_messages.each do |msg|
        break if msg.guid == etag
        temp_messages.push msg
      end

      return head :not_modified if temp_messages.empty?

      @at_messages = temp_messages
    end

    # Reverse is needed to have the messages shown in ascending timestamp
    @at_messages.reverse!

    # Get the ids of the messages to be shown
    at_messages_ids = @at_messages.map &:id

    # And increment their tries
    at_messages_ids.each do |at_message_id|
      AtMessage.where(:id => at_message_id).update_all "state = 'delivered', tries = tries + 1"
    end

    # Separate messages into ones that have their tries
    # over max_tries and those still valid.
    valid_messages, invalid_messages = @at_messages.partition { |msg| msg.tries < @account.max_tries }

    # Mark as failed messages that have their tries over max_tries
    invalid_messages.each do |invalid_message|
      AtMessage.where(:id => invalid_message.id).update_all "state = 'failed'"
    end

    # Logging: say that valid messages were returned and invalid no
    AtMessage.log_delivery(@at_messages, @account, 'rss')

    @at_messages = valid_messages
    return head :not_modified if @at_messages.empty?

    response.last_modified = @at_messages.last.timestamp
    response.headers['ETag'] = @at_messages.last.guid
    render :layout => false
  end

  # POST /:account_name/:aplication_name/rss
  def create
    tree = request.POST.present? ? request.POST : Hash.from_xml(request.raw_post).with_indifferent_access

    ActiveRecord::Base.transaction do
      items = tree[:rss][:channel][:item]
      items = [items] if items.class <= Hash
      items.each do |item|
        # Create AO message
        msg = AoMessage.new
        msg.from = item[:author]
        msg.to = item[:to]
        msg.subject = item[:title]
        msg.body = item[:description]
        msg.guid = item[:guid] unless item[:guid].nil?
        msg.timestamp = item[:pubDate].to_datetime

        # And let the account handle it
        @application.route_ao msg, 'rss'
      end
    end

    head :ok
  end
end

# Define 'to' tag inside 'item'
module RSS; class Rss; class Channel; class Item
  install_text_element "to", "", '?', "to", :string, "to"
end; end; end; end

RSS::BaseListener.install_get_text_element "", "to", "to="
