class CreateTickets < ActiveRecord::Migration
  def self.up
    create_table :tickets do |t|
      t.string :code
      t.string :secret_key
      t.string :status
      t.text :data
      t.datetime :expiration

      t.timestamps
    end
  end

  def self.down
    drop_table :tickets
  end
end
