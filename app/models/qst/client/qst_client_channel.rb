class QstClientChannel < Channel
  include CronChannel

  configuration_accessor :url, :user, :password

  validates_presence_of :url, :user, :password

  def self.title
    "QST client"
  end

  def handle(msg)
    # AO Message should be queued, we just query them
  end

  def create_tasks
    create_task 'qst-client-channel-push', QST_PUSH_INTERVAL, PushQstChannelMessageJob.new(account_id, id)
    create_task 'qst-client-channel-pull', QST_PULL_INTERVAL, PullQstChannelMessageJob.new(account_id, id)
  end

  def destroy_tasks
    drop_task 'qst-client-channel-push'
    drop_task 'qst-client-channel-pull'
  end
end
