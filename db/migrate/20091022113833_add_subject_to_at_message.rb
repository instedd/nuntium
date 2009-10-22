class AddSubjectToAtMessage < ActiveRecord::Migration
  def self.up
    add_column :at_messages, :subject, :string
  end

  def self.down
    remove_column :at_messages, :subject
  end
end
