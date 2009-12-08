class DtacController < ApplicationController
  before_filter :authenticate

  # GET /dtac/geochat
  def index
    File.open('C:\\dtac-nuntium.log', 'a'){ |fh| fh.puts "#{Time.now.utc} Invoked dtac with '#{params.to_s}'" }
  
	msg = ATMessage.new
    msg.application_id = 1 #hardcoded!
    msg.from = 'sms://' + params[:MSISDN]
    msg.to = 'sms://' + params[:SMSCODE]
    msg.subject = params[:CONTENT]
    msg.guid = params[:ID]
    msg.timestamp = Time.now.utc
    msg.state = 'queued'
    msg.save!
    
    head :ok
  
  end
  
  def authenticate
    #TODO: Authenticate request incoming from DTAC
    true
  end
end
