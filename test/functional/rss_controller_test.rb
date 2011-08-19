require 'test_helper'
require 'base64'
require 'digest/md5'
require 'yaml'

class RssControllerTest < ActionController::TestCase
  def setup
    @account = Account.make
    @chan = Channel.make :qst_server, :account => @account
    @application = Application.make :account => @account, :password => 'app_pass'
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'app_pass')
  end

  def create(msg)
    @request.env['RAW_POST_DATA'] = new_rss_feed msg
    post :create, :account_name => @account.name, :application_name => @application.name
    assert_response :ok
  end

  def index(options = {})
    options.each do |k, v|
      @request.env[k] = v unless k == :expected_response
    end
    get :index, :account_name => @account.name, :application_name => @application.name
    assert_response (options[:expected_response] || :ok)
  end

  test "should convert one rss item to out message" do
    expected = AoMessage.make_unsaved
    create expected

    messages = AoMessage.all
    assert_equal 1, messages.length

    msg = messages[0]

    assert_equal @account.id, msg.account_id
    assert_equal @application.id, msg.application_id
    [:subject, :body, :from, :to, :guid].each do |field|
      assert_equal expected.send(field), msg.send(field)
    end
    assert_equal time_for_msg(0) , msg.timestamp
    assert_equal @chan.id, msg.channel_id
  end

  test "should create qst outgoing message" do
    create AoMessage.make_unsaved

    messages = AoMessage.all
    assert_equal 1, messages.length

    unread = QstOutgoingMessage.all
    assert_equal 1, unread.length
    assert_equal messages[0].id, unread[0].ao_message_id
    assert_equal @chan.id, unread[0].channel_id
  end

  test "should convert one message to rss item" do
    application2 = Application.make :account => @account

    msg = AtMessage.make :account => @account, :application => @application, :state => 'queued'
    AtMessage.make :account => @account, :application => application2, :state => 'queued'

    index

    assert_equal msg.timestamp, @response.last_modified

    assert_select "title", "Outbox"
    assert_select "lastBuildDate", msg.timestamp.rfc822
    assert_select "guid", :count => 1 do |es|
      assert_equal 1, es.length
    end
    assert_shows_message_as_rss_item msg
  end

  test "should convert one message with empty subject to rss item" do
    msg = AtMessage.make :account => @account, :application => @application, :state => 'queued', :subject => ''

    index

    assert_equal msg.timestamp, @response.last_modified

    assert_select "title", "Outbox"
    assert_select "lastBuildDate", msg.timestamp.rfc822
    assert_select "guid", :count => 1 do |es|
      assert_equal 1, es.length
    end
    assert_shows_message_as_rss_item msg
  end

  test "should convert one message without subject to rss item" do
    msg = AtMessage.make :account => @account, :application => @application, :state => 'queued', :subject => nil
    index
    assert_shows_message_as_rss_item msg
  end

  test "should convert two messages to rss items ordered by timestamp" do
    2.times { |i| AtMessage.make :account => @account, :application => @application, :timestamp => time_for_msg(i), :state => 'queued' }

    index

    assert_select "title", "Outbox"
    assert_select "pubDate" do |es|
      assert_equal 2, es.length
      assert_select es[0], "pubDate", 'Sun, 02 Jan 2000 05:00:00 +0000'
      assert_select es[1], "pubDate", 'Mon, 03 Jan 2000 05:00:00 +0000'
    end
  end

  test "should return not modified for HTTP_IF_MODIFIED_SINCE" do
    2.times { AtMessage.make :account => @account, :application => @application, :timestamp => time_for_msg(0), :state => 'queued' }
    index "HTTP_IF_MODIFIED_SINCE" => time_for_msg(1).to_s, :expected_response => :not_modified
  end

  test "should apply HTTP_IF_MODIFIED_SINCE" do
    AtMessage.make :account => @account, :application => @application, :state => 'queued', :timestamp => time_for_msg(0)
    msg = AtMessage.make :account => @account, :application => @application, :state => 'queued', :timestamp => time_for_msg(1)

    index "HTTP_IF_MODIFIED_SINCE" => time_for_msg(0).to_s

    assert_select "title", "Outbox"
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    assert_shows_message_as_rss_item msg
  end

  test "should apply HTTP_IF_MODIFIED_SINCE and increment tries" do
    msg_0 = new_at_message(@application, 0)
    msg_1 = new_at_message(@application, 1)

    @request.env["HTTP_IF_MODIFIED_SINCE"] = time_for_msg(0).to_s

    1.upto 5 do |try|
      get :index, :account_name => @account.name, :application_name => @application.name

      msgs = AtMessage.all
      assert_equal 2, msgs.length
      assert_equal 0, msgs[0].tries

      if 1 <= try and try <= 3
        assert_select "guid" do |es|
          assert_equal 1, es.length
        end
        assert_equal try, msgs[1].tries
        assert_equal 'delivered', msgs[1].state
      else
        assert_select "guid", {:count => 0}
        assert_equal 4, msgs[1].tries
        assert_equal 'failed', msgs[1].state
      end
    end
  end

  test "should return not modified for HTTP_IF_NONE_MATCH" do
    new_at_message(@application, 0)
    new_at_message(@application, 1)

    index "HTTP_IF_NONE_MATCH" => "someguid 1", :expected_response => :not_modified
  end

  test "should apply HTTP_IF_NONE_MATCH" do
    new_at_message(@application, 0)
    msg = new_at_message(@application, 1)

    index "HTTP_IF_NONE_MATCH" => "someguid 0"

    assert_select "title", "Outbox"
    assert_select "guid" do |es|
      assert_equal 1, es.length
    end
    assert_shows_message_as_rss_item msg
  end

  test "create not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'wrong_pass')
    post :create, :account_name => @account.name, :application_name => @application.name
    assert_response 401
  end

  test "index not authorized" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'wrong_pass')
    get :index, :account_name => @account.name, :application_name => @application.name
    assert_response 401
  end

  test "index not found name mismatch 1" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("account2/#{@application.name}", 'app_pass')
    get :index, :account_name => @account.name, :application_name => @application.name
    assert_response 401
  end

  test "index not found name mismatch 2" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/application2", 'app_pass')
    get :index, :account_name => @account.name, :application_name => @application.name
    assert_response 401
  end

  test "authenticate with appplication@account" do
    new_at_message(@application, 0)
    new_at_message(@application, 1)

    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@application.name}@#{@account.name}", 'app_pass')
    index "HTTP_IF_NONE_MATCH" => "someguid 1", :expected_response => :not_modified
  end

  # Utility methods follow
  def new_rss_feed(msg)
    result = <<-eos
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <item>
            <title>#{msg.subject}</title>
            <description>#{msg.body}</description>
            <author>#{msg.from}</author>
            <to>#{msg.to}</to>
            <pubDate>Sun Jan 02 05:00:00 UTC 2000</pubDate>
            <guid>#{msg.guid}</guid>
          </item>
        </channel>
      </rss>
    eos
    result.strip
  end

  def assert_shows_message_as_rss_item(msg)
    if msg.subject.blank?
      assert_select "item title", msg.body
      assert_select "item description", {:count => 0}
    else
      assert_select "item title", msg.subject
      assert_select "item description", msg.body
    end

    assert_select "item author", msg.from
    assert_select "item to", msg.to
    assert_select "item guid", msg.guid
    assert_select "item pubDate", msg.timestamp.rfc822
  end

end
