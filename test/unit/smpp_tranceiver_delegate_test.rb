require 'test_helper'
require 'mocha'
require 'smpp'

class SmppTranceiverDelegateTest < ActiveSupport::TestCase
  include Mocha::API
  
  def setup
    @application = Application.create!(:name => "testapp", :password => "testpass")
    @chan = Channel.new(:application_id => @application.id, :name => 'chan', :kind => 'smpp', :protocol => 'sms')
    @chan.configuration = {:host => 'host', :port => '3200', :source_ton => 0, :source_npi => 0, :destination_ton => 0, :destination_npi => 0, :user => 'user', :password => 'password', :system_type => 'smpp' }
    @transceiver = mock('Smpp::Transceiver')
  end

  def send_message(encodings, input, output, output_coding, endianness = :big)
    @chan.configuration[:mt_encodings] = encodings
    @chan.configuration[:endianness] = endianness.to_s
     @chan.configuration[:default_mo_encoding] = 'ascii'
    @chan.save!
    
    @transceiver.expects(:send_mt).with(123, '8888', '4444', output, { :data_coding => output_coding })
    
    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    @delegate.send_message(123, '8888', '4444', input)
  end
  
  def receive_message(input, input_coding, output, options = {})
    @chan.configuration[:mt_encodings] = ['ascii']
    @chan.configuration[:endianness] = options.fetch(:endianness, :big).to_s
    @chan.configuration[:default_mo_encoding] = options.fetch(:default_mo_encoding, 'ascii')
    @chan.configuration[:accept_mo_hex_string] = options.fetch(:accept_mo_hex_string, false) ? '1' : '0'
    @chan.save!
    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    
    pdu_options = {:data_coding => input_coding}
    pdu_options[:esm_class] = options[:esm_class] if options.include? :esm_class
    if options.include? :optional_parameters
      optionals = {}
      options[:optional_parameters].each do |x, y|
        optionals[x] = Smpp::OptionalParameter.new(x, y)
      end
      pdu_options[:optional_parameters] = optionals
    end
    
    
    pdu = Smpp::Pdu::DeliverSm.new '4444', '8888', input, pdu_options
    @delegate.mo_received @transceiver, pdu
    
    if options.fetch(:part, false)
      part = SmppMessagePart.last
      assert_not_nil part
      assert_equal @chan.id, part.channel_id
      assert_equal options[:reference_number], part.reference_number
      assert_equal options[:part_count], part.part_count
      assert_equal options[:part_number], part.part_number
      assert_equal output, part.text
    else
      msgs = ATMessage.all
      assert_equal 1, msgs.length
      msg = msgs[0]
      assert_equal 'sms://4444', msg.from
      assert_equal 'sms://8888', msg.to
      assert_equal output, msg.subject
      assert_equal @chan.id, msg.channel_id
    end
  end

  test "send ascii message" do
    send_message ['ascii'], 'Hello', 'Hello', 1
  end
  
  test "send ascii message as latin1" do
    send_message ['latin1'], 'Hello', 'Hello', 3
  end
  
  test "send ascii message as ascii" do
    send_message ['ascii', 'latin1'], 'Hello', 'Hello', 1
  end
  
  test "send latin1 message as latin1" do
    send_message ['ascii', 'latin1'], 'árbol', "\341rbol", 3
  end
  
  test "send ascii message as ucs2" do
    send_message ['ucs-2'], 'hola', "\000h\000o\000l\000a", 8
  end
  
  test "send unicode message as ucs2" do    
    send_message ['ascii', 'latin1', 'ucs-2'], "你好", "\117\140\131\175", 8
  end
  
  test "send ucs2 little endian" do
    send_message ['ucs-2'], 'hola', "h\000o\000l\000a\000", 8, :little
  end
  
  test "receive ascii message" do
    receive_message 'hello', 1, 'hello'
  end
  
  test "receive latin1 message" do
    receive_message "\341rbol", 3, 'árbol'
  end
  
  test "receive ucs2 message" do
    receive_message "\000h\000o\000l\000a", 8, 'hola'
  end
  
  test "receive usc2-le message" do
    receive_message "h\000o\000l\000a\000", 8, 'hola', :endianness => :little
  end
  
  test "receive default encoding message" do
    receive_message "h\000o\000l\000a\000", 0, 'hola', :endianness => :little, :default_mo_encoding => 'ucs-2'
  end
  
  test "receive hex string" do
    receive_message "006100620063", 0, 'abc', :accept_mo_hex_string => true
  end
  
  test "receive hex string not hex" do
    receive_message "h\000o\000l\000a\000", 8, 'hola', :endianness => :little, :accept_mo_hex_string => true
  end
  
  test "receive lao message" do
    pdubin = '0000003d000000050000000000002a6f00000038353632303232313032383900000032343838000000000000000000000c306538313065383230653834'
    pdu = Smpp::Pdu::Base.create(pdubin.scan(/../).map{|x| x.to_i(16).chr}.join)
    
    @chan.configuration[:mt_encodings] = ['ascii']
    @chan.configuration[:endianness] = :big
    @chan.configuration[:default_mo_encoding] = 'ascii'
    @chan.configuration[:accept_mo_hex_string] = '1'
    @chan.save!
    @delegate = SmppTransceiverDelegate.new(@transceiver, @chan)
    
    @delegate.mo_received @transceiver, pdu
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    msg = msgs[0]
    assert_equal 'sms://856202210289', msg.from
    assert_equal 'sms://2488', msg.to
    assert_equal "ກຂຄ", msg.subject
    assert_equal @chan.id, msg.channel_id 
  end
  
  test "receive unkonwn encoding" do
    receive_message "h\000o\000l\000a\000", 7, "h\000o\000l\000a\000"
  end
  
  test "receive concatenated sms with udh creates part" do
    receive_message "\005\000\003\123\003\001hola", 0, 'hola', :part => true, :esm_class => 64, :reference_number => 0123, :part_count => 3, :part_number => 1
  end
  
  test "receive concatenated sms with udh creates message" do
    receive_message "\005\000\003\123\003\001uno", 0, 'uno', :part => true, :esm_class => 64, :reference_number => 0123, :part_count => 3, :part_number => 1
    receive_message "\005\000\003\123\003\002dos", 0, 'dos', :part => true, :esm_class => 64, :reference_number => 0123, :part_count => 3, :part_number => 2
    receive_message "\005\000\003\123\003\003tres", 0, 'unodostres', :esm_class => 64
    assert_equal 0, SmppMessagePart.count
  end
  
  test "receive sms with udh" do
    receive_message "\005\001\003\123\003\001hola", 0, 'hola', :part => false, :esm_class => 64
  end
  
  test "receive concatenated sms with optional parameters" do
    receive_message "hola", 0, 'hola', :part => true, :optional_parameters => { 0x020c => "\x00\x3d", 0x020e =>  "\x03", 0x020f => "\x01"}, :reference_number => 0x3d, :part_count => 3, :part_number => 1
  end
  
  test "reassemble concatenated sms with optional parameters" do
    receive_message "uno", 0, 'uno', :part => true, :optional_parameters => { 0x020c => "\x00\x3d", 0x020e =>  "\x03", 0x020f => "\x01"}, :reference_number => 0x3d, :part_count => 3, :part_number => 1
    receive_message "dos", 0, 'dos', :part => true, :optional_parameters => { 0x020c => "\x00\x3d", 0x020e =>  "\x03", 0x020f => "\x02"}, :reference_number => 0x3d, :part_count => 3, :part_number => 2
    receive_message "tres", 0, 'unodostres', :optional_parameters => { 0x020c => "\x00\x3d", 0x020e =>  "\x03", 0x020f => "\x03"}
    assert_equal 0, SmppMessagePart.count
  end
  
  test "receive message from payload" do
    receive_message '', 0, 'hola mundo', :optional_parameters => { 0x0424 => "hola mundo"}
  end
  
end
