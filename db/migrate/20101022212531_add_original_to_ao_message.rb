class AddOriginalToAoMessage < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :original, :text
  end

  def self.down
    remove_column :ao_messages, :original
  end
end
