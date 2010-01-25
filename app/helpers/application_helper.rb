# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def short(msg, length = 15)
    if msg.nil?
      return ''
    end
    
    if msg.length > length
      msg[0 ... length] + "..."
    else
      msg
    end
  end
  
  def short_html(msg, length = 15)
    '<span title="' + (h msg) + '">' + short(msg, length) + '</span>'
  end
  
  def time_ago(time)
    return '' if time.nil?
    '<span title="' + time.utc.to_s + '">' + time_ago_in_words(time.utc, true) + ' ago</span>'
  end
end
