require 'rss/1.0'
require 'rss/2.0'

class RssController < ApplicationController
  before_filter :authenticate

  # GET /rss
  def index
    last_modified = request.env['HTTP_IF_MODIFIED_SINCE']
    etag = request.env['HTTP_IF_NONE_MATCH']
    
    conditions = 'application_id = ?'
    if last_modified.nil?
      conditions = [conditions, @application.id]
    else
      conditions = [conditions + ' AND timestamp > ?', @application.id, DateTime.parse(last_modified)]
    end
    
    @ao_messages = ATMessage.all(:order => 'timestamp DESC', :conditions => conditions)
    
    if @ao_messages.length == 0
      head :not_modified
      return
    end
    
    if !etag.nil?
      temp_messages = []
      @ao_messages.each do |msg|
        if msg.guid == etag
          break
        end
        temp_messages.push msg
      end
      
      if temp_messages.length == 0
        head :not_modified
        return
      else
        @ao_messages = temp_messages.reverse
      end
    else
      @ao_messages.reverse!
    end
  end
  
  # POST /rss
  def create
    body = request.env['RAW_POST_DATA']
    tree = RSS::Parser.parse(body, false)
    
    tree.channel.items.each do |item|
      msg = AOMessage.new
      msg.application_id = @application.id
      msg.from = item.author
      msg.to = item.to
      msg.body = item.description
      msg.guid = item.guid.content
      msg.timestamp = item.pubDate.to_datetime
      msg.save
      
      outgoing = QSTOutgoingMessage.new
      outgoing.channel_id = @channel.id
      outgoing.guid = msg.guid
      outgoing.save
    end
     
    head :ok
  end
  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @application = Application.first(:conditions => ['name = ? AND password = ?', username, password]) 
      if !@application.nil?
        @channel = @application.channels.first(:conditions => ['kind = ?', :qst])
      end
      !@application.nil?
    end
  end
end

# Define 'to' tag inside 'item'
module RSS; class Rss; class Channel; class Item
  install_text_element "to", "", '?', "to", :string, "to"
end; end; end; end

RSS::BaseListener.install_get_text_element "", "to", "to="
