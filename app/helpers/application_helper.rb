# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def edit_channel_header
    if @channel.new_record?
      "<h4>Create new #{params[:kind].gsub('_', ' ')} channel</h4>"
    else
      "<h4>Edit #{@channel.name} channel</h4>"
    end
  end
  
  def form_for_channel
    form_for :channel, :url => { :controller => 'channel', :action => (@channel.new_record? ? :create_channel : :update_channel), :kind => @channel.kind || params[:kind] } do |f|
      yield f
    end
  end
  
  def edit_channel_name(f)
    if @channel.new_record?
      "<p>\r\n" + 
      "#{f.label :name}<br/>\r\n" +
      "#{f.text_field :name}\r\n" +
      "</p>" 
    end
  end
  
  def edit_channel_protocol(f, default_protocol = nil)
    "<p>\r\n" + 
    "#{f.label :protocol}<br/>\r\n" +
    "#{f.text_field :protocol, :value => @channel[:protocol] || default_protocol}\r\n" +
    "</p>" 
  end
  
  def channel_submit_tag
    submit_tag (@channel.new_record? ? 'Create Channel' : 'Update Channel')
  end

  def short(msg, length = 15)
    return '' if msg.nil?
    msg.length > length ? (msg[0 ... length] + "...") : msg
  end
  
  def short_html(msg, length = 15)
    '<span title="' << (h msg) << '">' << short(msg, length) << '</span>'
  end
  
  def time_ago(time)
    return '' if time.nil?
    '<span title="' << time.utc.to_s << '">' << time_ago_in_words(time.utc, true) << ' ago</span>'
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
