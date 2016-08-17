# See http://stackoverflow.com/questions/21075515/creating-tables-and-problems-with-primary-key-in-rails
# and https://github.com/rails/rails/pull/13247#issuecomment-32425844
class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
end