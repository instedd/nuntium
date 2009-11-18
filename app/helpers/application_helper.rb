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
    '<a title="' + (h msg) + '">' + short(msg, length) + '</a>'
  end
  
  def js(name, js_function)
    "<a href=\"javascript:void(0)\" onclick=\"#{js_function}\">#{name}</a>"
  end 
end
