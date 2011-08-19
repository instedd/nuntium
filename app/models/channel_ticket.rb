module ChannelTicket
  extend ActiveSupport::Concern

  included do
    attr_accessor :ticket_code, :ticket_message

    before_save :ticket_record_password, :if => lambda { ticket_code }
    after_create :ticket_mark_as_complete, :if => lambda { ticket_code }
  end

  module InstanceMethods
    def ticket_record_password
      ticket = Ticket.find_by_code_and_status ticket_code, 'pending'
      if ticket.nil?
        errors.add(:ticket_code, "Invalid code")
        return false
      end
      self.address = ticket.data[:address]
      @password_input = configuration[:password]
      return true
    end

    def ticket_mark_as_complete
      ticket = Ticket.complete ticket_code, { :channel => self.name, :account => self.account.name, :password => @password_input, :message => self.ticket_message }
    end
  end
end
