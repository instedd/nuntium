class RestartProcessJob

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def perform(manager)
    manager.restart_process id
  end
  
  def to_s
    "<RestartProcess:#{id}>"
  end

end
