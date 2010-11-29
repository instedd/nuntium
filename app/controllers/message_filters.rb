module MessageFilters

  def build_ao_messages_filter
    @ao_page = params[:ao_page]
    @ao_page = 1 if @ao_page.blank?
    @ao_search = params[:ao_search]
    @ao_previous_search = params[:ao_previous_search]
    # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
    @ao_page = 1 if !@ao_previous_search.blank? and @ao_previous_search != @ao_search
    @ao_conditions = build_message_filter(@ao_search)
  end

  def build_at_messages_filter
    @at_page = params[:at_page]
    @at_page = 1 if @at_page.blank?
    @at_search = params[:at_search]
    @at_previous_search = params[:at_previous_search]
    # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
    @at_page = 1 if !@at_previous_search.blank? and @at_previous_search != @at_search
    @at_conditions = build_message_filter(@at_search)
  end

  def build_logs_filter
    @log_page = params[:log_page]
    @log_page = 1 if @log_page.blank?
    @log_search = params[:log_search]
    @log_previous_search = params[:log_previous_search]
    # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
    @log_page = 1 if !@log_previous_search.blank? and @log_previous_search != @log_search
    @log_conditions = build_log_filter(@log_search)
  end

  def build_message_filter(search)
    def esc(name)
      ActiveRecord::Base.connection.quote_column_name(name)
    end

    search = Search.new(search)
    conds = ['account_id = :account_id', { :account_id => @account.id }]
    if search.search
      conds[0] << ' AND ('
      # Add id condition only if searching a number
      if search.search.integer?
        conds[0] << 'id = :search_exact OR '
      end
      conds[0] << "#{esc('guid')} LIKE :search OR channel_relative_id LIKE :search OR #{esc('from')} LIKE :search OR #{esc('to')} LIKE :search OR subject LIKE :search OR body LIKE :search"
      conds[0] << ') '
      conds[1][:search_exact] = search.search
      conds[1][:search] = "%#{search.search}%"
    end

    [:id, :tries].each do |sym|
      if search[sym]
        op, val = get_op_and_val search[sym]
        if val.integer?
          conds[0] << " AND #{sym} #{op} :#{sym}"
          conds[1][sym] = val.to_i
        else
          conds[0] << " AND id = 0"
        end
      end
    end
    [:guid, :channel_relative_id, :from, :to, :subject, :body, :state].each do |sym|
      if search[sym]
        conds[0] << " AND #{esc(sym)} LIKE :#{sym}"
        conds[1][sym] = "%#{search[sym]}%"
      end
    end
    if search[:after]
      after = parse_time(search[:after])
      if after
        conds[0] << " AND #{esc('timestamp')} >= :after"
        conds[1][:after] = after
      end
    end
    if search[:before]
      before = parse_time(search[:before])
      if before
        conds[0] << " AND #{esc('timestamp')} <= :before"
        conds[1][:before] = before
      end
    end
    if search[:updated_at]
      updated_at = parse_time(search[:updated_at])
      if updated_at
        next_day = updated_at + 1.day
        conds[0] << " AND #{esc('updated_at')} >= :updated_at AND #{esc('updated_at')} < :updated_at_next_day"
        conds[1][:updated_at] = updated_at
        conds[1][:updated_at_next_day] = next_day
      end
    end
    if search[:channel]
      channel = @account.find_channel search[:channel]
      if channel
        conds[0] << ' AND channel_id = :channel_id'
        conds[1][:channel_id] = channel.id
      else
        conds[0] << ' AND channel_id = 0'
      end
    end
    if search[:application]
      app = @account.find_application search[:application]
      if app
        conds[0] << ' AND application_id = :application_id'
        conds[1][:application_id] = app.id
      else
        conds[0] << ' AND application_id = 0'
      end
    end
    conds
  end

  def get_op_and_val(val)
    op = '='
    if val.length > 1 && (val[0..1] == '<=' || val[0..1] == '>=')
      op = val[0..1]
      val = val[2..-1]
    elsif val.length > 0 && (val[0].chr == '<' || val[0].chr == '>')
      op = val[0].chr
      val = val[1..-1]
    end
    [op, val]
  end

  def build_log_filter(search)
    search = Search.new(search)
    conds = ['account_id = :account_id', { :account_id => @account.id }]
    if search.search
      conds[0] << ' AND ('
      conds[0] << 'message LIKE :search'

      severity = AccountLog.severity_from_text search.search
      if severity != 0
        conds[0] << ' OR severity = :search_severity'
        conds[1][:search_severity] = severity
      end

      conds[0] << ') '
      conds[1][:search] = "%#{search.search}%"
    end
    if search[:severity]
      op, val = get_op_and_val search[:severity]
      conds[0] << " AND severity #{op} :severity"
      conds[1][:severity] = AccountLog.severity_from_text val
    end
    [:ao, :ao_message_id, :ao_message].each do |sym|
      if search[sym]
        op, val = get_op_and_val search[sym]
        if val.integer?
          conds[0] << " AND ao_message_id #{op} :#{sym}"
          conds[1][sym] = val.to_i
        else
          conds[0] << " AND id = 0"
        end
      end
    end
    [:at, :at_message_id, :at_message].each do |sym|
      if search[sym]
        op, val = get_op_and_val search[sym]
        if val.integer?
          conds[0] << " AND at_message_id #{op} :#{sym}"
          conds[1][sym] = val.to_i
        else
          conds[0] << " AND id = 0"
        end
      end
    end
    if search[:after]
      after = parse_time(search[:after])
      if after
        conds[0] << ' AND created_at >= :after'
        conds[1][:after] = after
      end
    end
    if search[:before]
      before = parse_time(search[:before])
      if before
        conds[0] << ' AND created_at <= :before'
        conds[1][:before] = before
      end
    end
    if search[:channel]
      channel = @account.find_channel search[:channel]
      if channel
        conds[0] << ' AND channel_id = :channel_id'
        conds[1][:channel_id] = channel.id
      else
        conds[0] << ' AND channel_id = 0'
      end
    end
    if search[:application]
      app = @account.find_application search[:application]
      if app
        conds[0] << ' AND application_id = :application_id'
        conds[1][:application_id] = app.id
      else
        conds[0] << ' AND application_id = 0'
      end
    end
    conds
  end

  def parse_time(time)
    if time.include?('ago') ||
      time.include?('year') || time.include?('month') || time.include?('day') ||
      time.include?('hour') || time.include?('minute') || time.include?('second')

      # Replace words with numbers
      @@numbers.each_with_index do |n, i|
        time = (i + 1).to_s << time[n.length .. -1] if time.starts_with?(n)
      end

      return nil if time.to_i == 0

      time = time.gsub(' ', '.')
      result = eval(time)
      return result.class <= Time || result.class <= ActiveSupport::TimeWithZone ? result : nil
    else
      return Time.parse(time)
    end
  rescue Exception => e
    return nil
  end

  @@numbers = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

end
