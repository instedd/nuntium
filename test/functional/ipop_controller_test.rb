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
    get :index, params

    msgs = AOMessage.all
    assert_equal 1, msgs.length
    msg = msgs[0]

    assert_equal "sms://#{params[:hp]}", msg.from
    assert_equal params[:ts][0 .. -4], msg.timestamp.strftime('%Y%m%d%H%M%S')
    assert_equal params[:txt], msg.body
    assert_equal params[:ts], msg.channel_relative_id
    assert_equal @chan.id, msg.channel_id

    assert_response :ok
    assert_equal 'OK', @response.body
  end
end
