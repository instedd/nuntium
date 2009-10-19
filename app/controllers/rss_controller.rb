require 'rss/1.0'
require 'rss/2.0'

class RssController < ApplicationController
  # GET /rss
  def index
    last_modified = request.env['HTTP_IF_MODIFIED_SINCE']
    etag = request.env['HTTP_IF_NONE_MATCH']
    
    if last_modified.nil?
      @ao_messages = ATMessage.all(:order => 'timestamp DESC')
    else
      @ao_messages = ATMessage.all(:order => 'timestamp DESC', :conditions => ['timestamp > ?', DateTime.parse(last_modified)])
      if @ao_messages.length == 0
        head :not_modified
        return
      end
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
      msg.from = item.author
      msg.to = item.to
      msg.body = item.description
      msg.guid = item.guid.content
      msg.timestamp = item.pubDate.to_datetime
      msg.save
      
      unread = UnreadAOMessage.new
      unread.guid = msg.guid
      unread.save
    end
     
    head :ok
  end  
end

# Define 'to' tag inside 'item'
module RSS; class Rss; class Channel; class Item
  install_text_element "to", "", '?', "to", :string, "to"
end; end; end; end

RSS::BaseListener.install_get_text_element "", "to", "to="
