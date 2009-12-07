class DtacController < ApplicationController
  before_filter :authenticate

  # GET /dtac/geochat
  def index
    #TODO: Process incoming message, convert to AT and save
    File.open('C:\\dtac-nuntium.log', 'a'){ |fh| fh.puts "#{Time.now.utc} Invoked dtac with '#{params.to_s}'" }
  end
  
  def authenticate
    #TODO: Authenticate request incoming from DTAC
    true
  end
end
