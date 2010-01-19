class CreateSmppMessageParts < ActiveRecord::Migration
  def self.up
    create_table :smpp_message_parts do |t|
      t.integer :reference_number
      t.integer :part_count
      t.integer :part_number
      t.string :text

      t.timestamps
    end
  end

  def self.down
    drop_table :smpp_message_parts
  end
end
