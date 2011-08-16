class AccountLog < ActiveRecord::Base
  belongs_to :account
  belongs_to :application
  belongs_to :channel
  belongs_to :ao_message
  belongs_to :at_message

  Info = 1
  Warning = 2
  Error = 3

  def severity_text
    case severity
    when Info then 'info'
    when Warning then 'warning'
    when Error then 'error'
    end
  end

  def severity_html
    case severity
    when Info then '<span style="color:#0D0D68">info</span>'
    when Warning then '<span style="color:#FF8B17">warning</span>'
    when Error then '<span style="color:red">error</span>'
    end
  end

  def self.severity_from_text(text)
    text = text.downcase
    return Info if 'info'.starts_with? text
    return Warning if 'warning'.starts_with? text
    return Error if 'error'.starts_with? text
    return 0
  end

  def self.search(search)
    result = self

    search = Search.new search
    if search.search
      severity = AccountLog.severity_from_text search.search
      if severity == 0
        result = result.where 'message LIKE ?', "%#{search.search}%"
      else
        result = result.where 'message LIKE ? OR severity = ?', "%#{search.search}%", severity
      end
    end
    if search[:severity]
      op, val = Search.get_op_and_val search[:severity]
      result = result.where "severity #{op} ?", AccountLog.severity_from_text(val)
    end
    [:ao, :ao_message_id, :ao_message].each do |sym|
      if search[sym]
        op, val = Search.get_op_and_val search[sym]
        result = result.where "ao_message_id #{op} ?", val.to_i
      end
    end
    [:at, :at_message_id, :at_message].each do |sym|
      if search[sym]
        op, val = Search.get_op_and_val search[sym]
        result = result.where "at_message_id #{op} ?", val.to_i
      end
    end
    if search[:after]
      after = Time.smart_parse search[:after]
      result = result.where 'created_at >= ?', after if after
    end
    if search[:before]
      before = Time.smart_parse search[:before]
      result = result.where 'created_at <= ?', before if before
    end
    result = result.joins(:channel).where 'channels.name = ?', search[:channel] if search[:channel]
    result = result.joins(:application).where 'applications.name = ?', search[:application] if search[:application]
    result
  end
end
