require 'rss/1.0'
require 'rss/2.0'

class OutMessagesController < ApplicationController
  # POST /out_messages
  def create
    body = request.env['RAW_POST_DATA']
    tree = RSS::Parser.parse(body, false)
    
    tree.channel.items.each do |item|
      msg = OutMessage.new
      msg.from = item.author
      msg.body = item.description
      msg.guid = item.guid.content
      msg.save
    end
     
    head :ok
  end
end
