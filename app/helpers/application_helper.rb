# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def short(msg, length = 15)
    return '' if msg.nil?
    msg.length > length ? (msg[0 ... length] + "...") : msg
  end

  def short_html(msg, length = 15)
    ('<span title="' << (h msg) << '">' << h(short(msg, length)) << '</span>').html_safe
  end

  def message_subject(msg)
    if logged_in_application && msg.application != logged_in_application
      '*' * msg.subject.length
    else
      msg.subject
    end
  end

  def message_body(msg)
    if logged_in_application && msg.application != logged_in_application
      '*' * msg.body.length
    else
      msg.body
    end
  end

  def time_ago(time)
    return '' if time.nil?
    ('<span title="' << time.utc.to_s << '">' << time_ago_in_words(time.utc, true) << ' ago</span>').html_safe
  end

  def go_back_link
    link_to 'Go back', :controller => :home, :action => :index
  end

  def nuntium_version
    begin
      @@nuntium_version = File.read('VERSION').strip unless defined? @@nuntium_version
    rescue Errno::ENOENT
      @@nuntium_version = 'Development'
    end
    @@nuntium_version
  end
end
