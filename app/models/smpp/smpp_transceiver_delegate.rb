require 'iconv'

class SmppTransceiverDelegate
  
  EncodingCode = { "ascii" => 1, "latin1" => 3, "ucs-2be" => 8, "ucs-2le" => 8 }
  
  def initialize(transceiver, channel)
    @transceiver = transceiver
    @channel = channel
    @encodings = @channel.configuration[:mt_encodings].map { |x| encoding_endianized x }
  end
  
  def send_message(id, from, to, text)
    
    msg_text = nil
    msg_coding = nil
    
    # Select best encoding for the message
    @encodings.each do |encoding|
      iconv = Iconv.new(encoding, 'utf-8')
      msg_text = iconv.iconv(text) rescue next
      msg_coding = EncodingCode[encoding]
      break
    end
    
    @transceiver.send_mt(id, from, to, msg_text, {:data_coding => msg_coding})
  end
  
  def mo_received(transceiver, pdu)
    msg = ATMessage.new
    msg.from = pdu.source_addr.with_protocol 'sms'
    msg.to = pdu.destination_addr.with_protocol 'sms'
    if @channel.configuration[:accept_mo_hex_string] == '1' and is_hex(pdu.short_message) 
      bytes = hex_to_bytes pdu.short_message
      iconv = Iconv.new('utf-8', ucs2_endianized)
      msg.subject = iconv.iconv bytes
    else
      source_encoding = case pdu.data_coding
        when 0: encoding_endianized(@channel.configuration[:default_mo_encoding])
        when 1: 'ascii'
        when 3: 'latin1'
        when 8: ucs2_endianized
      end
      
      if source_encoding
        iconv = Iconv.new('utf-8', source_encoding)
        msg.subject = iconv.iconv pdu.short_message
      else
        msg.subject = pdu.short_message
      end
    end
    
    @channel.accept msg
  end
  
  private
  
  def encoding_endianized(encoding)
    encoding == 'ucs-2' ? ucs2_endianized : encoding
  end
  
  def ucs2_endianized
    @channel.configuration[:endianness] == 'little' ? 'ucs-2le' : 'ucs-2be'
  end
  
  def is_hex(msg)
    msg =~ /[0-9a-fA-F]{4}+/
  end
  
  def hex_to_bytes(msg)
    msg.scan(/../).map{|x| x.to_i(16).chr}.join
  end
  
end
