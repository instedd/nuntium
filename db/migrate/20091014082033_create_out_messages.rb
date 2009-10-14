class CreateOutMessages < ActiveRecord::Migration
  def self.up
    create_table :out_messages do |t|
      t.primary_key :id
      t.string :from
      t.string :to
      t.text :body
      t.timestamp :timestamp

      t.timestamps
    end
  end

  def self.down
    drop_table :out_messages
  end
end
