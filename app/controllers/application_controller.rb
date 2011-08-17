# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  # protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Given an array of AOMessage or ATMessage, this methods
  # returns two arrays:
  #  - The first one has the messages which have tries < account.max_tries
  #  - The second one has the messages which have tries >= account.max_tries
  def filter_tries_exceeded_and_not_exceeded(msgs, account)
    valid_messages = []
    invalid_messages = []

    msgs.each do |msg|
      if msg.tries >= account.max_tries
        invalid_messages.push msg
      else
        valid_messages.push msg
      end
    end

    [valid_messages, invalid_messages]
  end
end
