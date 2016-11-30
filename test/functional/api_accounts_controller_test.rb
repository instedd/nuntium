require 'test_helper'

class ApiAccountsControllerTest < ActionController::TestCase
  test 'list accounts' do
    Guisso.stubs(:enabled?).returns(true)
    user = User.make
    account = Account.make_unsaved(name: "foo")
    user.create_account account
    token = {
      "user" => user.email,
      "expires_at" => "3016-08-23T15:11:21.000Z",
      "token_type" => "bearer",
      "client" => {
        "name" => "app",
        "client_id" => "CBl1h6joPyisXkYCvgHz7g"
      }
    }
    AltoGuissoRails.stubs(:validate_oauth2_request).returns(token)
    @controller.env["guisso.oauth2.req"] = "guisso_request"

    get :index
    assert_response :ok
    assert_equal ['foo'], JSON.parse(@response.body)
  end
end
