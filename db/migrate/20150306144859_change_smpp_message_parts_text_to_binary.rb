class ChangeSmppMessagePartsTextToBinary < ActiveRecord::Migration
  def up
    change_column :smpp_message_parts, :text, :binary, :limit => 255
  end

  def down
    change_column :smpp_message_parts, :text, :string
  end
end
