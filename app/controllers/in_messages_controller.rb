require 'rss/1.0'
require 'rss/2.0'

class InMessagesController < ApplicationController
  # GET /in_messages
  def index
    last_modified = request.env['If-Modified-Since']
    etag = request.env['ETag']
    
    if last_modified.nil?
      @in_messages = InMessage.all(:order => 'timestamp DESC')
    else
      @in_messages = InMessage.all(:order => 'timestamp DESC', :conditions => ['timestamp > ?', DateTime.parse(last_modified)])
      if @in_messages.length == 0
        head :not_modified
      end
    end
    
    if !etag.nil?
      temp_messages = []
      @in_messages.each do |msg|
        if msg.guid == etag
          break
        end
        temp_messages.push msg
      end
      
      if temp_messages.length == 0
        head :not_modified
      else
        @in_messages = temp_messages
      end
    end
  end
end
