require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable


  def where(params)
    where = params.keys.map { |key| "#{key} = ?" }.join('AND')
    DBConnection.execute(<<-SQL, *(params.values))
    SELECT
      *
    FROM
      #{self.class.table_name}
    WHERE
      #{where}
    SQL
    ##still failing
  end
end

class SQLObject
  # Mixin Searchable here...
end
