require 'net/pop'
require 'tmail'

class ReceivePop3MessageJob

  attr_accessor :account_id, :channel_id

  include CronTask::QuotedTask

  def initialize(account_id, channel_id)
    @account_id = account_id
    @channel_id = channel_id
  end

  def perform
    account = Account.find @account_id
    @channel = account.channels.find_by_id @channel_id
    config = @channel.configuration
    remove_quoted = config[:remove_quoted_text_or_text_after_first_empty_line].to_b

    pop = Net::POP3.new(config[:host], config[:port].to_i)
    pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if config[:use_ssl].to_b

    begin
      pop.start(config[:user], config[:password])
    rescue Net::POPAuthenticationError => ex
      @channel.alert "#{ex}"

      @channel.enabled = false
      @channel.save!
      return
    end

    pop.each_mail do |mail|
      tmail = TMail::Mail.parse(mail.pop)
      tmail_body = get_body tmail

      sender = (tmail.from || []).first
      receiver = (tmail.to || []).first

      msg = AtMessage.new
      msg.from = "mailto://#{sender}"
      msg.to = "mailto://#{receiver}"
      msg.subject = tmail.subject
      msg.body = tmail_body
      if remove_quoted
        Rails.logger.error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Rails.logger.error msg.body
        msg.body = ReceivePop3MessageJob.remove_quoted_text_or_text_after_first_empty_line msg.body
      end
      msg.channel_relative_id = tmail.message_id
      msg.timestamp = tmail.date

      # Process references to set the thread and reply_to
      if tmail.references
        tmail.references.each do |ref|
          at_index = ref.index('@')
          next unless ref.start_with?('<') || !at_index
          if ref.end_with?('@message_id.nuntium>')
            msg.custom_attributes['reply_to'] = ref[1 .. -21]
          elsif ref.end_with?('.nuntium>')
            msg.custom_attributes["references_#{ref[at_index + 1 .. -10]}"] = ref[1 ... at_index]
          end
        end
      end

      account.route_at msg, @channel

      mail.delete
      break if not has_quota?
    end

    pop.finish
  rescue => ex
    AccountLogger.exception_in_channel @channel, ex if @channel
  end

  def self.remove_quoted_text_or_text_after_first_empty_line(text)
    result = ""
    text.strip.lines.each do |line|
      line = line.strip
      break if line.empty?
      break if line.start_with? '>'
      break if line.start_with?('On') && line.end_with?(':')
      result << line
      result << "\n"
    end
    result.strip
  end

  private

  def get_body(tmail)
    # Not multipart? Return body as is.
    return tmail.body if !tmail.multipart?

    # Return text/plain part.
    tmail.parts.each do |part|
      return part.body if part.content_type == 'text/plain'
    end

    # Or body if not found
    return tmail.body
  end
end
