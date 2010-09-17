class AlertMailer < ActionMailer::Base
  def error(account, subject, body)
    @subject = "[Nuntium Alerts] #{subject}"
    @recipients = account.alert_emails.split(',').map{|x| x.strip}
    @from = 'nuntium@instedd.org'
    @body["message"] = body
    @headers = {}
   end
end
