require 'test_helper'

class PushQstChannelMessageJobTest < ActiveSupport::TestCase

  def setup
    @channel = Channel.make :qst_client
    
    @job = PushQstChannelMessageJob.new @channel.account_id, @channel.id
    @job.batch_size = 3
    
    @client = mock('QstClient')
    QstClient.expects(:new).with(@channel.configuration[:url], @channel.configuration[:user], @channel.configuration[:password]).returns(@client)    
  end
  
  test "no messages" do
    @client.expects(:get_last_id)
    @client.expects(:put_messages).times(0)
    
    @job.perform
  end
  
  test "one message no previous last id" do
    @msg = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued'
    
    @client.expects(:get_last_id).returns(nil)
    @client.expects(:put_messages).with([@msg.to_qst]).returns(@msg.guid)
    
    @job.perform
    
    @channel.reload
    assert_equal @msg.guid, @channel.configuration[:last_ao_guid]
    
    @msg.reload
    assert_equal 'confirmed', @msg.state
    assert_equal 1, @msg.tries
  end
  
  test "two messages with previous last id" do
    @msg1 = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued', :timestamp => Time.now
    @msg2 = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued', :timestamp => Time.now + 1
    
    @client.expects(:get_last_id).returns(@msg1.guid)
    @client.expects(:put_messages).with([@msg2.to_qst]).returns(@msg2.guid)
    
    @job.perform
    
    @channel.reload
    assert_equal @msg2.guid, @channel.configuration[:last_ao_guid]
    
    @msg1.reload
    assert_equal 'confirmed', @msg1.state
    assert_equal 0, @msg1.tries
    
    @msg2.reload
    assert_equal 'confirmed', @msg2.state
    assert_equal 1, @msg2.tries
  end
  
  test "two messages no previous last id but only one confirmed" do
    @msg1 = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued', :timestamp => Time.now
    @msg2 = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued', :timestamp => Time.now + 1
    
    @client.expects(:get_last_id).returns(nil)
    @client.expects(:put_messages).with([@msg1.to_qst, @msg2.to_qst]).returns(@msg1.guid)
    
    @job.perform
    
    @channel.reload
    assert_equal @msg1.guid, @channel.configuration[:last_ao_guid]
    
    @msg1.reload
    assert_equal 'confirmed', @msg1.state
    assert_equal 1, @msg1.tries
    
    @msg2.reload
    assert_equal 'delivered', @msg2.state
    assert_equal 1, @msg2.tries
  end
  
  test "authentication exception disables channel" do
    @msg = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued'
    
    response = mock('Response')
    response.stubs(:code => 401)
    
    @client.expects(:get_last_id).returns(nil)
    @client.expects(:put_messages).with([@msg.to_qst]).raises(QstClient::Exception.new response) 
    
    @job.perform
    
    @channel.reload
    assert_nil @channel.configuration[:last_at_guid]
    assert_false @channel.enabled
  end
  
  test "check has quota if returned messages equal batch size" do
    @job.batch_size = 1
    
    @msg1 = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued', :timestamp => Time.now
    @msg2 = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued', :timestamp => Time.now + 1
    
    @client.expects(:get_last_id).returns(nil)
    
    # Adding many expects put them in a stack, so we specify them backwards
    @client.expects(:put_messages).with([@msg2.to_qst]).returns(@msg2.guid)
    @client.expects(:put_messages).with([@msg1.to_qst]).returns(@msg1.guid)
    
    @job.expects('has_quota?').returns(false)
    @job.expects('has_quota?').returns(true)
    
    @job.perform
  end

	test "one message no previous last id correct queued count" do
    @msg = AOMessage.make :account => @channel.account, :channel => @channel, :state => 'queued'

		assert_equal 1, @channel.queued_ao_messages_count
    
    @client.expects(:get_last_id).returns(nil)
    @client.expects(:put_messages).with([@msg.to_qst]).returns(@msg.guid)
    
    @job.perform

		assert_equal 0, @channel.queued_ao_messages_count
  end

end
