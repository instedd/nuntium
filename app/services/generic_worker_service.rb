class GenericWorkerService < Service

  PrefetchCount = 1

  attr_reader :sessions

  def initialize(id, working_group, suspension_time = 5 * 60)
    @id = id
    @working_group = working_group
    @suspension_time = suspension_time
  end

  def start
    Rails.logger.info "Starting"
    MQ.error { |err| Rails.logger.error err }

    @sessions = {}
    @temporarily_unsubscribed = Set.new
    @notifications_session = MQ.new

    WorkerQueue.find_each(:conditions => ['working_group = ? AND enabled = ?', @working_group, true]) do |wq|
      subscribe_to_queue wq
    end

    Queues.subscribe_notifications(@id, @working_group, @notifications_session) do |header, job|
      job.perform self
    end
  end

  def subscribe_to_queue(wq)
    wq_name = wq.kind_of?(WorkerQueue) ? wq.queue_name : wq
    return if @temporarily_unsubscribed.include? wq_name

    wq = WorkerQueue.find_by_queue_name wq unless wq.kind_of? WorkerQueue
    return unless wq and wq.enabled
    return if @sessions.include? wq.queue_name

    Rails.logger.info "Subscribing to queue #{wq.queue_name} with ack #{wq.ack} and durable #{wq.durable}"

    mq = MQ.new
    mq.prefetch PrefetchCount
    @sessions[wq.queue_name] = mq

    Queues.subscribe(wq.queue_name, wq.ack, wq.durable, mq) do |header, job|
      begin
        Rails.logger.debug "Executing job #{job} for queue #{wq.queue_name}"
        success = job.perform
        header.ack if success == true and wq.ack
      rescue Exception => ex
        Rails.logger.info "Temporary exception executing #{job} for queue #{wq.queue_name}: #{ex.class} #{ex} #{ex.backtrace}"

        if wq.ack
          Queues.publish_notification UnsubscribeTemporarilyFromQueueJob.new(wq.queue_name), @working_group, @notifications_session
        end
      end
    end
  end

  def unsubscribe_from_queue(wq_name)
    return if @temporarily_unsubscribed.include? wq_name

    Rails.logger.info "Unsubscribing from queue #{wq_name}"

    mq = @sessions.delete wq_name
    mq.close if mq
  end

  def unsubscribe_temporarily_from_queue(wq_name)
    return if @temporarily_unsubscribed.include? wq_name

    start_ignoring wq_name
    reactivate = proc { stop_ignoring wq_name }
    if @suspension_time == 0
      reactivate.call
    else
      EM.add_timer(@suspension_time) { reactivate.call }
    end
  end

  def start_ignoring(wq_name)
    unsubscribe_from_queue(wq_name)
    @temporarily_unsubscribed << wq_name
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
