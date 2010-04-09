class SendDtacMessageJob < SendMessageJob

  require 'iconv'

  def managed_perform
    str = @msg.subject_and_body
    encoded = ActiveSupport::Multibyte::Chars.u_unpack(str).map { |i| i.to_s(16).rjust(4, '0') }
    
    File.open(File.join(RAILS_ROOT, 'log', 'dtac.log'), 'a') { 
      |fh|  
      fh.puts "Sending new AO message #{@msg.subject_and_body} #{encoded.to_s}"
    }
  
    response = Net::HTTP.post_form(
      URI.parse('http://corpsms.dtac.co.th/servlet/com.iess.socket.SmsCorplink'), {
        'RefNo'=>(0...14).map{ ('a'..'z').to_a[rand(26)] }.join, #HACK: DTAC supports only 15 chars for ID, we need to figure out what to use
        'Msn'=>@msg.to.without_protocol,
        'Sno'=>config[:sno],
        'Sender'=>config[:sno],
        'Msg'=>encoded.to_s,
        'Encoding'=>25,
        'MsgType'=>'H',
        'User' =>  config[:user],
        'Password' => config[:password]})
        
    if response.code[0,1] == "2" # HTTP OK
      # we have to check the status value, 0 means success
      values = {};
    
      # split the body and put the key-value pairs in a hash
      array = response.read_body.split("\n")
      array.each { |e| 
        ar = e.split("=")
        values[ar[0]] = ar[1]  
      }
    
      status = values["Status"].to_i
      if ( status == 0 )
        @msg.send_succeeed @app, @channel
      else
        @msg.send_failed @app, @channel, values['Message']
      end
    else
      @msg.send_failed @app, @channel, response.message
    end
    :success
  end
  
end
