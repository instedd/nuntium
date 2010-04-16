class StopProcessJob

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def perform(manager)
    manager.stop_process id
  end
  
  def to_s
    "<StopProcess:#{id}>"
  end

end
