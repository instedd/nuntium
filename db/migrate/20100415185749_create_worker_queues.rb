class CreateWorkerQueues < ActiveRecord::Migration
  def self.up
    create_table :worker_queues do |t|
      t.string, :queue_name
      t.string, :working_group
      t.boolean :ack
      t.boolean :enabled

      t.timestamps
    end
  end

  def self.down
    drop_table :worker_queues
  end
end
