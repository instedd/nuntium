class AlterTablesConvertToCharacterSetUtf8 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.tables.each do |table_name|
      ActiveRecord::Base.connection.execute "alter table #{table_name} convert to character set 'utf8'";
    end
  end

  def self.down
  end
end
