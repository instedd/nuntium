class CreateInMessages < ActiveRecord::Migration
  def self.up
    create_table :in_messages do |t|
      t.primary_key :id
      t.string :from
      t.string :to
      t.text :body
      t.string :guid

      t.timestamps
    end
  end

  def self.down
    drop_table :in_messages
  end
end
