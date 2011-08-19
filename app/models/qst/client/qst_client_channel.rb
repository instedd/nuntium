class QstClientChannel < Channel
  configuration_accessor :url, :user, :password

  validates_presence_of :url, :user, :password

  after_create :create_tasks, :if => :enabled?
  after_update :create_tasks, :if => lambda { (enabled_changed? && enabled) || (paused_changed? && !paused) }
  after_update :destroy_tasks, :if => lambda { (enabled_changed? && !enabled) || (paused_changed? && paused) }
  before_destroy :destroy_tasks, :if => :enabled?

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
