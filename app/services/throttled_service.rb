class ThrottledService < Service

  loop_with_sleep(60) do
    @worker ||= ThrottledWorker.new
    @worker.perform
  end

end
