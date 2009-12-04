class CreateTasksForExistingEntities < ActiveRecord::Migration
  def self.up
    Application.find_all_by_interface('qst').each { |app| app.send :handle_tasks, true }
    Channel.find_all_by_kind('pop3').each { |ch| ch.handler.send :after_create }
    Channel.find_all_by_kind('twitter').each { |ch| ch.handler.send :after_create }
  end

  def self.down
  end
end
