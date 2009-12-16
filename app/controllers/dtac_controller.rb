class DtacController < ApplicationController
  before_filter :authenticate
  require 'iconv'
  
  def index  
    File.open('c:\dtac.log', 'a'){ 
      |fh|  
      fh.puts 'Received new AT message'
      params.each { |k,v| 
        fh.puts(' ' + k.to_s + ': ' + v.to_s) 
      } 
    }
    
    converter = Iconv.new('UTF-8','TIS-620')
    text = converter.iconv(params[:CONTENT])

    msg = ATMessage.new
    msg.application_id = @application.id
    msg.from = 'sms://' + params[:MSISDN]
    msg.to = 'sms://' + params[:SMSCODE]
    msg.body = text
    msg.channel_relative_id = params[:ID]
    msg.timestamp = Time.now.utc
    msg.state = 'queued'
    msg.save!
    
    @application.logger.at_message_received_via msg, 'dtac'
    
    head :ok
  end
  
  def authenticate
    @application = Application.find_by_id(params[:application_id]) || Application.find_by_name(params[:application_id])
    return !@application.nil?
  end
  
end
