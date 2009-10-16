require 'rss/1.0'
require 'rss/2.0'

class RssController < ApplicationController
  # GET /rss
  def index
    last_modified = request.env['If-Modified-Since']
    etag = request.env['If-None-Match']
    
    if last_modified.nil?
      @out_messages = OutMessage.all(:order => 'timestamp DESC')
    else
      @out_messages = OutMessage.all(:order => 'timestamp DESC', :conditions => ['timestamp > ?', DateTime.parse(last_modified)])
      if @out_messages.length == 0
        head :not_modified
      end
    end
    
    if !etag.nil?
      temp_messages = []
      @out_messages.each do |msg|
        if msg.guid == etag
          break
        end
        temp_messages.push msg
      end
      
      if temp_messages.length == 0
        head :not_modified
      else
        @out_messages = temp_messages
      end
    end
  end
  
  # POST /rss
  def create
    body = request.env['RAW_POST_DATA']
    tree = RSS::Parser.parse(body, false)
    
    tree.channel.items.each do |item|
      msg = InMessage.new
      msg.from = item.author
      msg.body = item.description
      msg.guid = item.guid.content
      msg.timestamp = item.pubDate.to_datetime
      msg.save
    end
     
    head :ok
  end  
end
