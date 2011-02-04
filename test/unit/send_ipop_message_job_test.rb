require 'test_helper'

class SendIpopMessageJobTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make :ipop
    @msg = AOMessage.make :account => Account.make, :channel => @chan
    @query = {
      :sc => @chan.address,
      :hp => @msg.to.mobile_number,
      :ts => @msg.timestamp.strftime('%Y%m%d%H%M%S') + @msg.timestamp.milliseconds.to_s,
      :cid => @chan.configuration[:cid],
      :bid => @chan.configuration[:bid],
      :mt => 1,
      :txt => @msg.subject_and_body
    }
  end

  test "perform" do
    response = mock('Net::HTTPResponse')
    response.stubs(
      :code => '200',
      :message => 'OK',
      :content_type => 'text/plain',
      :read_body => 'OK')

    expect_post :url => @chan.configuration[:mt_post_url],
      :data => @query,
      :options => {:headers => {:content_type => "application/x-www-form-urlencoded"}},
      :returns => Net::HTTPSuccess,
      :returns_body => 'OK'

    deliver

    msg = AOMessage.first
    assert_equal 1, msg.tries
    assert_equal 'delivered', msg.state
    assert_equal "#{@msg.to.mobile_number}-#{@query[:ts]}", msg.channel_relative_id
  end

  def deliver
    job = SendIpopMessageJob.new(@chan.account.id, @chan.id, @msg.id)
    job.perform
  end
end
