# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def short(msg, length = 15)
    return '' if msg.nil?
    msg.length > length ? msg[0 ... length] + "..." : msg
  end
  
  def short_html(msg, length = 15)
    '<span title="' + (h msg) + '">' + short(msg, length) + '</span>'
  end
  
  def time_ago(time)
    return '' if time.nil?
    '<span title="' + time.utc.to_s + '">' + time_ago_in_words(time.utc, true) + ' ago</span>'
  end
end
