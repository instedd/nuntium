class GenericWorkerService < Service

  PrefetchCount = 1
  SuspensionTime = 5 * 60

  attr_reader :sessions

  def initialize(id, working_group)
    @id = id
    @working_group = working_group
  end

  def start
    Rails.logger.info "Starting"
    MQ.error { |err| Rails.logger.error err }

    @sessions = {}
    @temporarily_unsubscribed = Set.new
    @notifications_session = MQ.new

    subscribe_to_queues
    subscribe_to_notifications
  end

  def subscribe_to_queues
    WorkerQueue.find_each_enabled_for_working_group(@working_group) do |wq|
      subscribe_to_queue wq
    end
  end

  def subscribe_to_notifications
    Queues.subscribe_notifications(@id, @working_group, @notifications_session) do |header, job|
      job.perform self
    end
  end

  def subscribe_to_queue(wq)
    wq_name = wq.kind_of?(WorkerQueue) ? wq.queue_name : wq
    return if @temporarily_unsubscribed.include? wq_name

    wq = WorkerQueue.find_by_queue_name wq unless wq.kind_of? WorkerQueue
    return unless wq && wq.enabled
    return if @sessions.include? wq.queue_name

    Rails.logger.info "Subscribing to queue #{wq.queue_name} with ack #{wq.ack} and durable #{wq.durable}"
    wq.subscribe(mq_for wq) { |header, job| perform job, header, wq }
  end

  def mq_for(wq)
    mq = MQ.new
    mq.prefetch PrefetchCount
    @sessions[wq.queue_name] = mq
  end

  def perform(job, header, wq)
    Rails.logger.debug "Executing job #{job} for queue #{wq.queue_name}"
    job.perform
    header.ack if wq.ack
  rescue => ex
    Rails.logger.info "Exception executing #{job} for queue #{wq.queue_name}: #{ex.class} #{ex} #{ex.backtrace}"
    reschedule job, header, ex, wq if wq.ack
  end

  def reschedule(job, header, ex, wq)
    job.reschedule ex
  rescue => ex
    Rails.logger.info "Exception rescheduling #{job} for queue #{wq.queue_name}: #{ex.class} #{ex} #{ex.backtrace}"
    Queues.publish_notification UnsubscribeTemporarilyFromQueueJob.new(wq.queue_name), @working_group, @notifications_session
  else
    header.ack
  end

  def unsubscribe_from_queue(wq_name)
    return if @temporarily_unsubscribed.include? wq_name

    Rails.logger.info "Unsubscribing from queue #{wq_name}"
    @sessions.delete(wq_name).try(:close)
  end

  def unsubscribe_temporarily_from_queue(wq_name)
    return if @temporarily_unsubscribed.include? wq_name

    start_ignoring wq_name
    stop_ignoring_later wq_name
  end

  def start_ignoring(wq_name)
    unsubscribe_from_queue(wq_name)
    @temporarily_unsubscribed << wq_name
  end

  def stop_ignoring_later(wq_name)
    EM.add_timer(SuspensionTime) { stop_ignoring wq_name }
  end

  def stop_ignoring(wq_name)
    @temporarily_unsubscribed.delete wq_name
    subscribe_to_queue wq_name
  end

  def stop(stop_event_machine = true)
    Rails.logger.info "Stopping"

    super()

    @sessions.keys.each { |k| unsubscribe_from_queue k }
    @notifications_session.close
    EM.stop_event_loop if stop_event_machine
  end
end
