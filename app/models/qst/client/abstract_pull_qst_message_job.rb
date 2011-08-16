class AbstractPullQstMessageJob
  include CronTask::QuotedTask

  attr_accessor :batch_size

  def perform
    client = QstClient.new *get_url_user_and_password

    options = {:max => batch_size}

    begin
      options[:from_id] = load_last_id if load_last_id

      msgs = client.get_messages options
      msgs = message_class.from_qst msgs

      return if msgs.empty?

      msgs.each { |msg| route msg }

      save_last_id msgs.last.guid
    end while has_quota?
  rescue QstClient::Exception => ex
    if ex.response.code == 401
      on_401 "Pull Qst messages received unauthorized"
    else
      on_exception "Pull Qst messages received response code #{ex.response.code}"
    end
  end
end
