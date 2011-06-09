require 'test_helper'

class GetAoControllerTest < ActionController::TestCase
  def setup
    @account = Account.make
    @chan = Channel.make :account => @account
    @application = Application.make :account => @account, :password => 'app_pass'
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')
  end

  test "get ao as json no matches" do
    get :index, :account_name => @account.name, :application_name => @application.name, :token => '1234', :format => :json

    assert_response :ok

    messages = JSON.parse @response.body
    assert_equal 0, messages.length
  end

  test "get ao as json matches one" do
    token = 1234
    msg = AOMessage.make :account_id => @account.id, :application_id => @application.id, :token => token
    msg.country = 'ar'
    msg.save!

    get :index, :account_name => @account.name, :application_name => @application.name, :token => token, :format => :json

    messages = JSON.parse @response.body
    assert_equal 1, messages.length

    keys = ['from', 'to', 'subject', 'body', 'guid', 'state', 'country']
    assert_equal keys.sort, messages[0].keys.sort
    keys.each do |key|
      assert_equal msg.send(key), messages[0][key]
    end
  end
end
