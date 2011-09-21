class RestartChannelJob
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def perform(manager)
    manager.restart_channel id
  end

  def to_s
    "<RestartChannel:#{id}>"
  end
end
