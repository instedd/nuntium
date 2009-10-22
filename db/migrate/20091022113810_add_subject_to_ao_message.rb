class AddSubjectToAoMessage < ActiveRecord::Migration
  def self.up
    add_column :ao_messages, :subject, :string
  end

  def self.down
    remove_column :ao_messages, :subject
  end
end
