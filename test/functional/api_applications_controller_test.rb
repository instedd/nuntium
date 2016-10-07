require 'test_helper'

class ApiApplicationsControllerTest < ActionController::TestCase
  def setup
    @account = Account.make :password => 'secret'
    @application = Application.make :account => @account, :password => 'secret'
  end

  def authorize
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret')
  end

  test "show 'me' account" do
    authorize
    get :show, format: 'json', id: 'me'
    assert_response :ok

    json = JSON.parse @response.body
    assert_equal({
      "name" => @application.name,
      "interface" => {
        "type" => "rss",
        "url" => nil,
        "user" => nil
      },
      "use_address_source" => true,
      "strategy" => "single_priority",
      "delivery_ack" => {
        "url" => nil,
        "user" => nil,
        "method" => "none"
      },
      "twitter" => {
        "consumer_key" => nil
      }
    }, json)
  end

  test "set 'me' account" do
    authorize
    @request.env['RAW_POST_DATA'] = {
      "interface" => {
        "type" => "http_get_callback",
        "url" => "http://interface/url",
        "user" => "interface_user",
        "password" => "interface_password"
      },
      "use_address_source" => false,
      "strategy" => "broadcast",
      "delivery_ack" => {
        "url" => "http://ack/url",
        "user" => "ack_user",
        "password" => "ack_password",
        "method" => "post"
      }
    }.to_json
    put :update, format: 'json', id: 'me'
    assert_response :ok

    app = Application.find(@application.id)

    assert_equal "http_get_callback", app.interface
    assert_equal "http://interface/url", app.interface_url
    assert_equal "interface_user", app.interface_user
    assert_equal "interface_password", app.interface_password
    assert_equal false, app.use_address_source?
    assert_equal "broadcast", app.strategy
    assert_equal "http://ack/url", app.delivery_ack_url
    assert_equal "ack_user", app.delivery_ack_user
    assert_equal "ack_password", app.delivery_ack_password
    assert_equal "post", app.delivery_ack_method
  end
end
