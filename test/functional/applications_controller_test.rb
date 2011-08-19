require 'test_helper'

class ApplicationsControllerTest < ActionController::TestCase
  test "index" do
    account = Account.make
    get :index, {}, {:account_id => account.id}
    assert_template "index"
  end

  test "update rules in order" do
    account = Account.make
    apprules = {
      "7" => {
        "matchings" => {
          "8" => {"property"=>"application", "operator"=>"equals", "value"=>"c"},
          "9" => {"property"=>"application", "operator"=>"equals", "value"=>"d"},
          "10" => {"property"=>"application", "operator"=>"equals", "value"=>"e"}
        }, "actions" => {
          "11" => {"property"=>"application", "value"=>"a"},
          "12" => {"property"=>"application", "value"=>"b"},
          "13" => {"property"=>"application", "value"=>"c"}
        }
      },
      "1" => {
        "matchings" => {
          "2" => {"property"=>"application", "operator"=>"equals", "value"=>"a"}
        }, "actions" => {
          "3" => {"property"=>"application", "value"=>"a"}
        }
      },
      "4" => {
        "matchings" => {
          "5" => {"property"=>"application", "operator"=>"equals", "value"=>"b"}
        }, "actions" => {
          "6"=>{"property"=>"application", "value"=>"b"}
        }
      }
    }
    put :routing_rules, {:apprules => apprules}, {:account_id => account.id}

    account.reload

    rules = account.app_routing_rules
    assert_equal 3, rules.length
    assert_equal "a", rules[0]["matchings"].first["value"]
    assert_equal "b", rules[1]["matchings"].first["value"]
    assert_equal "c", rules[2]["matchings"].first["value"]
  end
end
