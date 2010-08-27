require 'test_helper'

class QueuedAoMessagesCountTest < ActiveSupport::TestCase
  def setup
    @chan = Channel.make
  end

  test "default count is zero" do
    assert_equal 0, @chan.queued_ao_messages_count
  end
  
  test "when an ao gets queued count gets incremented" do
    AOMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    assert_equal 1, @chan.queued_ao_messages_count
    
    AOMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    assert_equal 2, @chan.queued_ao_messages_count
  end
  
  test "when an ao gets out of queued count gets decremented" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    assert_equal 1, @chan.queued_ao_messages_count
    
    msg.state = 'delivered'
    msg.save!
    
    assert_equal 0, @chan.queued_ao_messages_count
  end
  
  test "when an ao does not change its state count is the same" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    assert_equal 1, @chan.queued_ao_messages_count
    
    msg.tries = 2
    msg.save!
    
    assert_equal 1, @chan.queued_ao_messages_count
  end
  
  test "delete cache key when deleting channel" do
    id = @chan.id
  
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    @chan.destroy
    
    assert_nil Rails.cache.read(Channel.queued_ao_messages_count_cache_key(id), :raw => true)
  end
  
  test "create cache key when creating channel" do
    assert_equal '0', Rails.cache.read(Channel.queued_ao_messages_count_cache_key(@chan.id), :raw => true)
  end
  
  test "don't modify cache key when updating channel" do
    msg = AOMessage.make :account => @chan.account, :channel => @chan, :state => 'queued'
    
    @chan.name = 'foo'
    @chan.save!
    
    assert_equal 1, @chan.queued_ao_messages_count
  end
  
  test "when an ao gets created but it's not queued don't increment" do
    AOMessage.make :account => @chan.account, :channel => @chan, :state => 'pending'
    AOMessage.make :account => @chan.account, :channel => @chan, :state => 'pending'
    AOMessage.make :account => @chan.account, :channel => @chan, :state => 'pending'
    
    Rails.cache.delete Channel.queued_ao_messages_count_cache_key(@chan.id)
    
    assert_equal 0, @chan.queued_ao_messages_count
  end
end  