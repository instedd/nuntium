require 'test_helper'

class ApiAoMessagesControllerTest < ActionController::TestCase
  def setup
    @account = Account.make :password => 'secret'
    @application = Application.make :account => @account, :password => 'secret'
  end

  def authorize
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret')
  end

  def create_test_ao_messages(token)
    @ao_msg1 = AoMessage.create! :account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'one', :to => 'sms://1', token: token
    @ao_msg2 = AoMessage.create! :account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'one', :to => 'sms://1', token: token
    @ao_msg3 = AoMessage.create! :account_id => @account.id, :application_id => @application.id, :state => 'pending', :body => 'two', :to => 'sms://1'
  end

  test "index as json" do
    create_test_ao_messages(token = Guid.new.to_s)
    authorize
    get :index, format: "json", token: token
    assert_response :ok

    assert_equal [
      {
        "to" => "sms://1",
        "body" => "one",
        "guid" => @ao_msg1.guid,
        "channel" => nil,
        "channel_kind" => nil,
        "state" => "pending"
      },
      {
        "to" => "sms://1",
        "body" => "one",
        "guid" => @ao_msg2.guid,
        "channel" => nil,
        "channel_kind" => nil,
        "state" => "pending"
      }
    ], JSON.parse(@response.body)
  end

  test "index as xml" do
    create_test_ao_messages(token = Guid.new.to_s)
    authorize
    get :index, format: "xml", token: token
    assert_response :ok

    assert_equal [
      {
        "from" => "",
        "id" => @ao_msg1.guid,
        "property" => { "name" => "token", "value" => token },
        "text" => "one",
        "to" => "sms://1"
      },
      {
        "from" => "",
        "id" => @ao_msg2.guid,
        "property" => { "name" => "token", "value" => token },
        "text" => "one",
        "to" => "sms://1"
      }
    ], Hash.from_xml(@response.body)["ao_messages"]["message"]
  end

  test "index requires the token param" do
    authorize
    get :index, format: "json"
    assert_response :bad_request
  end
end
