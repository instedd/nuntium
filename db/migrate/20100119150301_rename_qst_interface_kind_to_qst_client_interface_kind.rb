class RenameQstInterfaceKindToQstClientInterfaceKind < ActiveRecord::Migration
  def self.up
    Application.update_all("interface = 'qst_client'", "interface = 'qst'")
  end

  def self.down
    Application.update_all("interface = 'qst'", "interface = 'qst_client'")
  end
end
