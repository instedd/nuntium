require 'qst_client'

class AbstractPushQstMessageJob
  include CronTask::QuotedTask

  attr_accessor :batch_size

  def perform
    client = QstClient.new *get_url_user_and_password
    last_id = client.get_last_id

    last_msg = last_id ? message_class.find_by_guid(last_id) : nil

    mark_older_as_confirmed last_msg if last_msg

    begin
      msgs = fetch_newer_messages last_msg
      return if msgs.empty?

      last_id = client.put_messages message_class.to_qst(msgs)

      update_msgs_status msgs, max_tries, last_id
      message_class.log_delivery msgs, account, 'qst_client'

      save_last_id last_id

      return if msgs.length < batch_size
    end while has_quota?
  rescue QstClient::Exception => ex
    if ex.response.code == 401
      on_401 "Push Qst messages received unauthorized"
    else
      on_exception "Push Qst messages received response code #{ex.response.code}"
    end
  end

  private

  def fetch_newer_messages(last_msg)
    msgs = messages.with_state('delivered', 'queued').order(:timestamp).limit(batch_size)
    msgs = msgs.where 'timestamp > ?', last_msg.timestamp if last_msg
    msgs = msgs.all
  end

  def mark_older_as_confirmed(last_msg)
    messages.with_state('delivered', 'queued').where('timestamp <= ?', last_msg.timestamp).update_all "state = 'confirmed'"
  end

  def update_msgs_status(msgs, max_tries, last_guid)
    if last_guid.present?
      delivered_msgs_id = []
      confirmed_msgs_id = []
      current = confirmed_msgs_id
      msgs.each do |m|
        current << m.id
        current = delivered_msgs_id if last_guid == m.guid
      end
      update_tries confirmed_msgs_id, 'confirmed'
      update_tries delivered_msgs_id, 'delivered'
    else
      valid_msgs, invalid_msgs = msgs.partition {|m| m.tries < max_tries}
      update_tries valid_msgs.map(&:id)
      update_tries invalid_msgs.map(&:id), 'failed'
    end
  end

  def update_tries(ids, state=nil)
    return if ids.empty?

    stm = "tries = tries + 1"
    stm += ", state = '#{state}'" if state

    ids.each { |id| message_class.where(:id => id).update_all stm }
  end
end
