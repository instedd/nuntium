require 'test_helper'

class PullQstMessageJobTest < ActiveSupport::TestCase
  def setup
    @application = Application.make
    @application.interface_url = 'url'
    @application.interface_user = 'user'
    @application.interface_password = 'pass'
    @application.save!

    @channel = ClickatellChannel.make :account => @application.account

    @job = PullQstMessageJob.new @application.id
    @job.batch_size = 3

    @client = mock('QstClient')
    QstClient.expects(:new).with(@application.interface_url, @application.interface_user, @application.interface_password).returns(@client)
  end

  test "no messages" do
    @client.expects(:get_messages).with(:max => @job.batch_size).returns([])

    assert_equal 0, AoMessage.count

    @job.perform
  end

  test "one message no last id" do
    @msg = AoMessage.make_unsaved

    @client.expects(:get_messages).with(:max => @job.batch_size).returns([@msg.to_qst])

    @job.expects('has_quota?').returns(false)
    @job.perform

    @application.reload
    assert_equal @msg.guid, @application.last_ao_guid

    msgs = AoMessage.all
    assert_equal 1, msgs.length
    assert_equal @msg.to_qst, msgs[0].to_qst
    assert_equal @channel, msgs[0].channel
  end

  test "one message with last id" do
    @application.last_ao_guid = '1'
    @application.save!

    @client.expects(:get_messages).with(:max => @job.batch_size, :from_id => @application.last_ao_guid).returns([])

    @job.perform
  end

  test "two messages because has quota" do
    @msg1 = AoMessage.make_unsaved
    @msg2 = AoMessage.make_unsaved

    @client.expects(:get_messages).with(:max => @job.batch_size, :from_id => @msg1.guid).returns([@msg2.to_qst])
    @client.expects(:get_messages).with(:max => @job.batch_size).returns([@msg1.to_qst])

    @job.expects('has_quota?').returns(false)
    @job.expects('has_quota?').returns(true)

    @job.perform

    msgs = AoMessage.all
    assert_equal 2, msgs.length

    assert_equal @msg1.to_qst, msgs[0].to_qst
    assert_equal @channel, msgs[0].channel

    assert_equal @msg2.to_qst, msgs[1].to_qst
    assert_equal @channel, msgs[1].channel
  end

  test "authentication exception sets application interface to rss" do
    response = mock('Response')
    response.stubs(:code => 401)

    @client.expects(:get_messages).with(:max => @job.batch_size).raises(QstClient::Exception.new response)

    @job.perform

    @application.reload
    assert_equal 'rss', @application.interface
  end

end
