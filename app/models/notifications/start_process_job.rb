class StartProcessJob

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def perform(manager)
    manager.start_process id
  end
  
  def to_s
    "<StartProcess:#{id}>"
  end

end
