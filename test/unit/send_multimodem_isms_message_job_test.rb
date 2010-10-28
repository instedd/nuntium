require 'test_helper'

class SendMultimodemIsmsMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :multimodem_isms
  end

  should "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :body => 'ID: msgid')

    msg = AOMessage.make :account => Account.make, :channel => @chan, :guid => '1-2'

    expect_rest msg, response
    assert_true (deliver msg)

    msg = AOMessage.first
    assert_equal 'msgid', msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end

  def expect_rest(msg, response)
    params = ""
    params << "user=#{CGI.escape(@chan.configuration[:user])}&"
    params << "passwd=#{CGI.escape(@chan.configuration[:password])}&"
    params << "cat=1&"
    params << "to=#{CGI.escape(msg.to.without_protocol)}&"
    params << "text=#{CGI.escape(msg.subject_and_body)}"

    RestClient.expects(:get).with("http://#{@chan.configuration[:host]}:#{@chan.configuration[:port]}/sendmsg?#{params}").returns(response)
  end

  def deliver(msg)
    job = SendMultimodemIsmsMessageJob.new(@chan.account.id, @chan.id, msg.id)
    job.perform
  end

  def check_message_was_delivered(channel_relative_id)
    msg = AOMessage.first
    assert_equal channel_relative_id, msg.channel_relative_id
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
  end
end
