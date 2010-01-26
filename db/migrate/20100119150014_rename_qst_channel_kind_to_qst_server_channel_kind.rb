class RenameQstChannelKindToQstServerChannelKind < ActiveRecord::Migration
  def self.up
    Channel.update_all("kind = 'qst_server'", "kind = 'qst'")
  end

  def self.down
    Channel.update_all("kind = 'qst'", "kind = 'qst_server'")
  end
end
