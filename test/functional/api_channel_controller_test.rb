require 'test_helper'

class ApiChannelControllerTest < ActionController::TestCase

  def setup
    @account = Account.create! :name => 'acc', :password => 'acc_pass'
    @application = create_app @account
    @application2 = create_app @account, 10
    
    account2 = Account.create! :name => 'acc2', :password => 'acc_pass'
    app2 = create_app account2
    
    chan2 = new_channel account2, 'foobar'
    chan3 = new_channel @account, 'other-chan'
    chan3.application_id = @application2.id
    chan3.save!
  end
  
  def index(format, expected_channel_count)
    yield if block_given?
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    get :index, :format => format
    
    case format
    when 'xml'
      xml = Hash.from_xml(@response.body).with_indifferent_access
      chans = xml[:channels]
      if expected_channel_count == 0
        assert_nil chans
      else
        assert_equal expected_channel_count, chans[:channel].length
      end
    when 'json'
      json = JSON.parse @response.body
      assert_equal expected_channel_count, json.length
    end
  end
  
  def show(name, format, expected_channel_count)
    yield if block_given?
    
    @request.env['HTTP_AUTHORIZATION'] = http_auth('acc/application', 'app_pass')
    get :show, :format => format, :name => name
    
    if expected_channel_count == 0
      assert_response :not_found
      return
    else
      assert_response :ok
    end
    
    case format
    when 'xml'
      xml = Hash.from_xml(@response.body).with_indifferent_access
      assert_not_nil xml[:channel]
    when 'json'
      json = JSON.parse @response.body
      assert_not_nil json
    end
  end
  
  ['json', 'xml'].each do |format|
    test "index #{format} no channels" do
      index format, 0
    end
    
    test "index #{format} two channels" do
      index format, 2 do
        1.upto 2 do |i|
          chan = new_channel @account, "chan#{i}"
          chan.application_id = @application.id
          chan.save
        end
      end
    end
    
    test "index #{format} should also include channels that don't belong to any application" do
      index format, 3 do
        1.upto 2 do |i|
          chan = new_channel @account, "chan#{i}"
          chan.application_id = @application.id
          chan.save
        end
        chan = new_channel @account, "chan3"
      end
    end
    
    test "show #{format} not found" do
      show 'hola', format, 0
    end
    
    test "show #{format} for application found" do
      show 'hola', format, 1 do
        chan = new_channel @account, "hola"
        chan.application_id = @application.id
          chan.save
      end
    end
    
    test "show #{format} for no application found" do
      show 'hola', format, 1 do
        chan = new_channel @account, "hola"
      end
    end
  end

end
