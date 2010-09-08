class AddDurableToWorkerQueue < ActiveRecord::Migration
  def self.up
    add_column :worker_queues, :durable, :boolean, :default => true
  end

  def self.down
    remove_column :worker_queues, :durable
  end
end
