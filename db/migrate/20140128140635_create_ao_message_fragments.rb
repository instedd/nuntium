class CreateAoMessageFragments < ActiveRecord::Migration
  def change
    create_table :ao_message_fragments do |t|
      t.integer :account_id
      t.integer :channel_id
      t.integer :ao_message_id
      t.string :fragment_id
      t.integer :number

      t.timestamps
    end

    add_index :ao_message_fragments, [:account_id, :channel_id, :fragment_id, :number], :name => "index_ao_message_fragments"
  end
end
