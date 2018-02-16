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

# class SendNexmoMessageJobTest < ActiveSupport::TestCase
#   def setup
#     @chan = NexmoChannel.make
#   end

#   should "perform" do
#     msg = AoMessage.make :account => Account.make, :channel => @chan, :guid => '1-2'

#     json_response = %<{
#       "message-count": "1",
#       "messages": [
#         {
#           "status": "0",
#           "message-id": "msgid",
#           "to": "1234",
#           "remaining-balance": "1234",
#           "message-price": "1.2",
#           "network": "ARPA",
#           "client-ref": "#{msg.guid}"
#         }
#       ]
#     }>

#     response = mock('Net::HTTPResponse')
#     response.stubs(
#       :code => '200',
#       :message => 'OK',
#       :content_type => 'application/json',
#       :body => json_response)

#     expect_rest msg, response
#     deliver msg

#     msg = AoMessage.first
#     assert_equal 'msgid', msg.channel_relative_id
#     assert_equal ["0"], msg.custom_attributes["nexmo_status"]
#     assert_equal ["1234"], msg.custom_attributes["nexmo_remaining_balance"]
#     assert_equal ["1.2"], msg.custom_attributes["nexmo_message_price"]
#     assert_equal ["ARPA"], msg.custom_attributes["nexmo_network"]
#     assert_equal 1, msg.tries
#     assert_equal 'delivered', msg.state
#   end

#   should "perform but error" do
#     msg = AoMessage.make :account => Account.make, :channel => @chan, :guid => '1-2'

#     json_response = %<{
#       "message-count": "1",
#       "messages": [
#         {
#           "status": "2",
#           "error-text": "Oops"
#         }
#       ]
#     }>

#     response = mock('Net::HTTPResponse')
#     response.stubs(
#       :code => '200',
#       :message => 'OK',
#       :content_type => 'application/json',
#       :body => json_response)

#     expect_rest msg, response
#     deliver msg

#     msg = AoMessage.first
#     assert_equal ["2"], msg.custom_attributes["nexmo_status"]
#     assert_equal nil, msg.channel_relative_id
#     assert_equal 1, msg.tries
#     assert_equal 'failed', msg.state
#   end

#   def expect_rest(msg, response)
#     params = {
#       :from => @chan.from,
#       :to => msg.to.without_protocol,
#       :api_key => @chan.api_key,
#       :api_secret => @chan.api_secret,
#       :type => 'text',
#       :text => msg.body,
#       :"status-report-req" => '1',
#       :"client-ref" => msg.guid,
#       "callback" => "#{Settings.host_name}/#{msg.account_id}/#{@chan.id}/nexmo/#{@chan.callback_token}/ack",
#     }

#     RestClient.expects(:get).with("https://rest.nexmo.com/sms/json?#{params.to_query}",
#       headers: {"Content-Type" => "application/json"}).returns(response)
#   end

#   def deliver(msg)
#     job = SendNexmoMessageJob.new(@chan.account.id, @chan.id, msg.id)
#     job.perform
#   end
# end
