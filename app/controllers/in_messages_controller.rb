require 'rss/1.0'
require 'rss/2.0'

class InMessagesController < ApplicationController
  # GET /in_messages
  def index
    @in_messages = InMessage.all
  end
end
