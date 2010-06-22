require 'test_helper'

class PullQstChannelMessageJobTest < ActiveSupport::TestCase
  def setup
    @channel = Channel.make :qst_client
    
    @job = PullQstChannelMessageJob.new @channel.account_id, @channel.id
    @job.batch_size = 3
    
    @client = mock('QstClient')
    QstClient.expects(:new).with(@channel.configuration[:url], @channel.configuration[:user], @channel.configuration[:password]).returns(@client)    
  end
  
  test "no messages" do
    @client.expects(:get_messages).with(:max => @job.batch_size).returns([])
    
    assert_equal 0, ATMessage.count
    
    @job.perform
  end
  
  test "one message no last id" do
    @msg = ATMessage.make_unsaved
  
    @client.expects(:get_messages).with(:max => @job.batch_size).returns([@msg.to_qst])
    
    @job.expects('has_quota?').returns(false)
    @job.perform
    
    @channel.reload
    assert_equal @msg.guid, @channel.configuration[:last_at_guid]
    
    msgs = ATMessage.all
    assert_equal 1, msgs.length
    assert_equal @msg.to_qst, msgs[0].to_qst
  end
  
  test "one message with last id" do
    @channel.configuration[:last_at_guid] = '1'
    @channel.save!
  
    @client.expects(:get_messages).with(:max => @job.batch_size, :from_id => @channel.configuration[:last_at_guid]).returns([])
    
    @job.perform
  end
  
  test "two messages because has quota" do
    @msg1 = ATMessage.make_unsaved
    @msg2 = ATMessage.make_unsaved
  
    @client.expects(:get_messages).with(:max => @job.batch_size, :from_id => @msg1.guid).returns([@msg2.to_qst])
    @client.expects(:get_messages).with(:max => @job.batch_size).returns([@msg1.to_qst])
    
    @job.expects('has_quota?').returns(false)
    @job.expects('has_quota?').returns(true)
    
    @job.perform
    
    msgs = ATMessage.all
    assert_equal 2, msgs.length
    
    assert_equal @msg1.to_qst, msgs[0].to_qst
    assert_equal @msg2.to_qst, msgs[1].to_qst
  end
  
  test "authentication exception disables channel" do
    response = mock('Response')
    response.stubs(:code => 401)
  
    @client.expects(:get_messages).with(:max => @job.batch_size).raises(QstClient::Exception.new response)
    
    @job.perform
    
    @channel.reload
    assert_false @channel.enabled
  end
  
end
