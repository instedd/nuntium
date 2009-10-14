require 'test_helper'

class OutMessagesControllerTest < ActionController::TestCase
  test "should convert one rss item to out message" do
    @request.env['RAW_POST_DATA'] = <<-eos
      <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>First message</title>
              <description>Body of the message</description>
              <author>Someone</author>
              <pubDate>Tue, 03 Jun 2003 09:39:21 GMT</pubDate>
              <guid>someguid</guid>
            </item>
          </channel>
        </rss>
    eos
    post :create
    
    messages = OutMessage.all
    assert_equal(1, messages.length)
    
    msg = messages[0]
    assert_equal("Body of the message", msg.body)
    assert_equal("Someone", msg.from)
    assert_equal("someguid", msg.guid)
  end
end
