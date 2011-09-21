class StartChannelJob
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def perform(manager)
    manager.start_channel id
  end

  def to_s
    "<StartChannel:#{id}>"
  end
end
