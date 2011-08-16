module MessageState
  extend ActiveSupport::Concern

  module ClassMethods
    # Given a list of messages and the maximum retries count, updates their status
    # * if the processing was successful, messages are marked as confirmed up to the last ok id and delivered after
    # * if it failed, they are marked as failed if they exceeded max tries
    # * in either case, retries count is increased
    # * success of the process is determined by whether last guid is nil or not
    def update_msgs_status(msgs, max_tries, last_guid)
      if not last_guid.nil?
        delivered_msgs_id = []
        confirmed_msgs_id = []
        current = confirmed_msgs_id
        msgs.each do |m|
          current << m.id
          current = delivered_msgs_id if last_guid == m.guid
        end
        update_tries(confirmed_msgs_id, 'confirmed')
        update_tries(delivered_msgs_id, 'delivered')
      else
        valid_msgs, invalid_msgs= msgs.partition {|m| m.tries < max_tries}
        update_tries(valid_msgs.map(&:id))
        update_tries(invalid_msgs.map(&:id), 'failed')
      end
    end

    # Increases try count for all messages in ids collection, optionally also modifies state
    def update_tries(ids, state=nil)
      return if ids.empty?

      stm = "tries = tries + 1"
      stm += ", state = '#{state}'" if state

      ids.each { |id| self.update_all(stm, ['id = ?', id]) }
    end

    # Marks all older messages as confirmed
    # * if msg_or_id does not correspond to a valid message, no action is executed
    # * returns the message corresponding to msg_or_id if exists
    def mark_older_as_confirmed(msg_or_id, args)
      msg = self.get_message(msg_or_id)
      return nil if msg.nil?

      args[:before_timestamp] = msg.timestamp
      cond, params = "state IN ('delivered', 'queued')", []
      add_filter cond, params, args

      self.update_all("state = 'confirmed'", [cond] + params)
      return msg
    end

    # Returns all messages for an account or channel newer than a specific message
    # * all account's messages are returned if msg and msg_id is nil
    # * options include account_id, channel_id, desc, batch_size
    def fetch_newer_messages(msg_or_id, args)
      args = { :desc => false, :bach_size => 10 }.merge(args)
      raise Exception.new('Must set either channel or account id') if args[:account_id].nil? and args[:channel_id].nil?

      msg = self.get_message(msg_or_id)
      args[:after_timestamp] = msg.timestamp unless msg.nil?

      query = "state IN ('delivered', 'queued')"
      params = []

      # Filter by account/channel/timestamp
      add_filter query, params, args

      # Order by time, last arrived message will be first
      return self.all(
        :order => 'timestamp ' << (args[:desc] ? 'DESC' : 'ASC'),
        :conditions => [query] + params,
        :limit => args[:batch_size])
    end

    private

    def add_filter query, params, args
      # Filter by timestamp
      if args[:after_timestamp]
        query << ' AND timestamp > ?'
        params << args[:after_timestamp]
      end
      if args[:before_timestamp]
        query << ' AND timestamp <= ?'
        params << args[:before_timestamp]
      end

      # Filter by account
      if args[:account_id]
        query << " AND account_id = ?"
        params << args[:account_id]
      end

      # Filter by channel if requested
      if args[:channel_id]
        query << " AND channel_id = ?"
        params << args[:channel_id]
      end
    end
  end
end
