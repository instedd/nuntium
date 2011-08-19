require 'test_helper'

class IpopControllerTest < ActionController::TestCase
  def setup
    @account = Account.make
    @application = Application.make :account => @account
    @chan = Channel.make :ipop, :account => @account
  end

  test "index" do
    params = {
      :account_id => @chan.account.name,
      :channel_name => @chan.name,
      :hp => '1234',
      :ts => '20100527101112123',
      :cid => '1111',
      :txt => 'Hello!',
      :txtid => '987',
      :bl => '1'
    }
    post :index, params

    msgs = AtMessage.all
    assert_equal 1, msgs.length
    msg = msgs[0]

    assert_equal "sms://#{params[:hp]}", msg.from
    assert_equal "sms://#{@chan.address}", msg.to
    assert_equal params[:ts][0 .. -4], msg.timestamp.strftime('%Y%m%d%H%M%S')
    assert_equal params[:txt], msg.body
    assert_equal params[:ts], msg.channel_relative_id
    assert_equal @chan.id, msg.channel_id

    assert_response :ok
    assert_equal 'OK', @response.body
  end

  test "ack ok" do
    msg = AoMessage.make :account => @account, :application => @application, :channel => @chan, :channel_relative_id => '1234-5678'
    params = {
      :account_id => @chan.account.name,
      :channel_name => @chan.name,
      :hp => '1234',
      :ts => '5678',
      :st => 5
    }

    post :ack, params

    msg.reload
    assert_equal 'confirmed', msg.state

    logs = Log.all
    assert_equal 1, logs.length
    assert_equal msg.id, logs[0].ao_message_id
    assert_equal @chan.id, logs[0].channel_id
    assert_equal "Recieved status notification with status 5 (#{IpopChannelHandler::StatusCodes[5]})", logs[0].message
  end

  test "ack not ok" do
    msg = AoMessage.make :account => @account, :application => @application, :channel => @chan, :channel_relative_id => '1234-5678'
    params = {
      :account_id => @chan.account.name,
      :channel_name => @chan.name,
      :hp => '1234',
      :ts => '5678',
      :st => 6,
      :dst => 10
    }

    post :ack, params

    msg.reload
    assert_equal 'failed', msg.state

    logs = Log.all
    assert_equal 1, logs.length
    assert_equal msg.id, logs[0].ao_message_id
    assert_equal @chan.id, logs[0].channel_id
    assert_equal "Recieved status notification with status 6 (#{IpopChannelHandler::StatusCodes[6]}). Detailed status code 10: #{IpopChannelHandler::DetailedStatusCodes[10]}", logs[0].message
  end

  test "ack not ok for unknown message" do
    params = {
      :account_id => @chan.account.name,
      :channel_name => @chan.name,
      :hp => '1234',
      :ts => '5678',
      :st => 6,
      :dst => 10
    }

    response = post :ack, params
    assert_equal "NOK 1", response.body
  end
end
