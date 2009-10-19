class QstOutgoingMessageBelongsToChannel < ActiveRecord::Migration
  def self.up
    change_table :qst_outgoing_messages do |t|
      t.references :channel
    end
  end

  def self.down
    remove_column :qst_outgoing_messages, :channel_id
  end
end
