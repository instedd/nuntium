require 'iconv'

class SendDtacMessageJob < SendMessageJob
  def managed_perform
    str = @msg.subject_and_body
    encoded = ActiveSupport::Multibyte::Chars.u_unpack(str).map { |i| i.to_s(16).rjust(4, '0') }

    response = Net::HTTP.post_form(
      URI.parse('http://corpsms.dtac.co.th/servlet/com.iess.socket.SmsCorplink'), {
        'RefNo' => (0...14).map{ ('a'..'z').to_a[rand(26)] }.join, #HACK: DTAC supports only 15 chars for ID, we need to figure out what to use
        'Msn' => @msg.to.without_protocol,
        'Sno' => @msg.from.without_protocol,
        'Sender' => @msg.from.without_protocol,
        'Msg' => encoded.to_s,
        'Encoding' => 25,
        'MsgType' => 'H',
        'User' => @config[:user],
        'Password' => @config[:password]})

    if response.code[0,1] == "2" # HTTP OK
      # we have to check the status value, 0 means success
      values = {};

      # split the body and put the key-value pairs in a hash
      response_body = response.read_body
      array = response_body.split("\n")
      array.each { |e|
        ar = e.split("=")
        values[ar[0]] = ar[1]
      }

      status = values["Status"].to_i
      if ( status == 0 )
        @msg.send_succeed @account, @channel
      else
        error = DtacChannel::DTAC_ERRORS[status]

        raise response_body if error.nil?
        raise PermanentException.new(Exception.new("#{status}. #{error[:description]}")) if error[:kind] == :fatal
        raise MessageException.new(Exception.new("#{status}. #{error[:description]}")) if error[:kind] == :message
        raise response_body
      end
    else
      raise response.body
    end
  end
end
