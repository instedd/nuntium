class StopChannelJob
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def perform(manager)
    manager.stop_channel id
  end

  def to_s
    "<StopChannel:#{id}>"
  end
end
