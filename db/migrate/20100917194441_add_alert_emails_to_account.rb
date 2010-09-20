class AddAlertEmailsToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :alert_emails, :text
  end

  def self.down
    remove_column :accounts, :alert_emails
  end
end
