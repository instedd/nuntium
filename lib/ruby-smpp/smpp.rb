# SMPP v3.4 subset implementation.
# SMPP is a short message peer-to-peer protocol typically used to communicate 
# with SMS Centers (SMSCs) over TCP/IP.
#
# August Z. Flatby
# august@apparat.no

require 'logger'

$:.unshift(File.dirname(__FILE__))
require 'smpp/base.rb'
require 'smpp/transceiver.rb'
require 'smpp/pdu/base.rb'
require 'smpp/pdu/bind_base.rb'
require 'smpp/pdu/bind_resp_base.rb'

# Load all PDUs
Dir.glob(File.join(File.dirname(__FILE__), 'smpp', 'pdu', '*.rb')) do |f|
  require f unless f.match('base.rb$')
end

# Default logger. Invoke this call in your client to use another logger.
require (File.join(File.dirname(__FILE__), '..', '..', 'app', 'models', 'nuntium_logger'))
# Smpp::Base.logger = NuntiumLogger.new(STDOUT)
log_file = ARGV.length > 1 ? "ruby_smpp_#{ARGV[1]}.log" : "ruby_smpp.log"
Smpp::Base.logger = NuntiumLogger.new(File.join(File.dirname(__FILE__), '..', '..', 'log', log_file), 'ruby_smpp')
