# # Copyright (C) 2009-2012, InSTEDD
# #
# # This file is part of Nuntium.
# #
# # Nuntium is free software: you can redistribute it and/or modify
# # it under the terms of the GNU General Public License as published by
# # the Free Software Foundation, either version 3 of the License, or
# # (at your option) any later version.
# #
# # Nuntium is distributed in the hope that it will be useful,
# # but WITHOUT ANY WARRANTY; without even the implied warranty of
# # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# # GNU General Public License for more details.
# #
# # You should have received a copy of the GNU General Public License
# # along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

# require 'test_helper'

# class ReceiveMultimodemIsmsMessageJobTest < ActiveSupport::TestCase
#   def setup
#     @chan = MultimodemIsmsChannel.make!
#   end

#   should "perform with zero" do
#     msg = <<-END_OF_MESSAGE
# <?xml version="1.0" encoding="ISO-8859-1" ?><Response><Response_End>1</Response_End>
# <Unread_Available>1</Unread_Available>
# <Msg_Count>00</Msg_Count>
# </Response>
# END_OF_MESSAGE

#     response = mock('Net::HTTPResponse')
#     response.stubs(
#       :code => '200',
#       :message => 'OK',
#       :content_type => 'application/xml',
#       :body => msg)

#     params = ""
#     params << "user=#{CGI.escape(@chan.configuration[:user])}&"
#     params << "passwd=#{CGI.escape(@chan.configuration[:password])}"

#     RestClient.expects(:get).with("http://#{@chan.configuration[:host]}:#{@chan.configuration[:port]}/recvmsg?#{params}").returns(response)

#     job = ReceiveMultimodemIsmsMessageJob.new(@chan.account.id, @chan.id)
#     job.perform

#     msgs = AtMessage.all
#     assert_equal 0, msgs.length
#     assert_equal 0, Log.count
#   end

#   should "perform with one" do
#     msg = <<-END_OF_MESSAGE
# <?xml version="1.0" encoding="ISO-8859-1" ?><Response><Response_End>1</Response_End>
# <Unread_Available>1</Unread_Available>
# <Msg_Count>01</Msg_Count>
# <MessageNotification>
# <Message_Index>1</Message_Index>
# <ModemNumber>1:0774494369</ModemNumber>
# <SenderNumber>+93774494364</SenderNumber>
# <Date>28/10/09</Date>
# <Time>19:00:39</Time>
# <EncodingFlag>ASCII</EncodingFlag>
# <Message>This%20is%20a%20test%20message</Message>
# </MessageNotification>
# </Response>
# END_OF_MESSAGE

#     response = mock('Net::HTTPResponse')
#     response.stubs(
#       :code => '200',
#       :message => 'OK',
#       :content_type => 'application/xml',
#       :body => msg)

#     params = ""
#     params << "user=#{CGI.escape(@chan.configuration[:user])}&"
#     params << "passwd=#{CGI.escape(@chan.configuration[:password])}"

#     RestClient.expects(:get).with("http://#{@chan.configuration[:host]}:#{@chan.configuration[:port]}/recvmsg?#{params}").returns(response)

#     job = ReceiveMultimodemIsmsMessageJob.new(@chan.account.id, @chan.id)
#     job.perform

#     msgs = AtMessage.all
#     assert_equal 1, msgs.length

#     assert_equal "sms://93774494364", msgs[0].from
#     assert_equal "sms://0774494369", msgs[0].to
#     assert_equal ActiveSupport::TimeZone[@chan.configuration[:time_zone]].parse('09-10-28 19:00:39'), msgs[0].timestamp
#     assert_equal "This is a test message", msgs[0].body
#     assert_equal @chan.id, msgs[0].channel_id
#   end

#   should "perform with two" do
#     msg = <<-END_OF_MESSAGE
# <?xml version="1.0" encoding="ISO-8859-1" ?><Response><Response_End>1</Response_End>
# <Unread_Available>1</Unread_Available>
# <Msg_Count>02</Msg_Count>
# <MessageNotification>
# <Message_Index>1</Message_Index>
# <ModemNumber>1:0774494369</ModemNumber>
# <SenderNumber>+93774494364</SenderNumber>
# <Date>10/10/28</Date>
# <Time>19:00:39</Time>
# <EncodingFlag>ASCII</EncodingFlag>
# <Message>This%20is%20a%20test%20message</Message>
# </MessageNotification>
# <MessageNotification>
# <Message_Index>2</Message_Index>
# <ModemNumber>1:0774494369</ModemNumber>
# <SenderNumber>+93774494364</SenderNumber>
# <Date>10/10/28</Date>
# <Time>19:51:54</Time>
# <EncodingFlag>ASCII</EncodingFlag>
# <Message>Another%2Bone</Message>
# </MessageNotification>
# </Response>
# END_OF_MESSAGE

#     response = mock('Net::HTTPResponse')
#     response.stubs(
#       :code => '200',
#       :message => 'OK',
#       :content_type => 'application/xml',
#       :body => msg)

#     params = ""
#     params << "user=#{CGI.escape(@chan.configuration[:user])}&"
#     params << "passwd=#{CGI.escape(@chan.configuration[:password])}"

#     RestClient.expects(:get).with("http://#{@chan.configuration[:host]}:#{@chan.configuration[:port]}/recvmsg?#{params}").returns(response)

#     job = ReceiveMultimodemIsmsMessageJob.new(@chan.account.id, @chan.id)
#     job.perform

#     msgs = AtMessage.all
#     assert_equal 2, msgs.length

#     assert_equal "sms://93774494364", msgs[0].from
#     assert_equal "This is a test message", msgs[0].body
#     assert_equal @chan.id, msgs[0].channel_id

#     assert_equal "sms://93774494364", msgs[1].from
#     assert_equal "Another+one", msgs[1].body
#     assert_equal @chan.id, msgs[1].channel_id
#   end

# end
