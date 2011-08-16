class AlertMailer < ActionMailer::Base
  default :from => 'nuntium@instedd.org'

  def error(account, subject, body)
    subject = "[Nuntium Alerts] #{subject}"
    recipients = account.alert_emails.split(',').map{|x| x.strip}

    @message = body

    mail(:to => recipients, :subject => subject)
   end
end
