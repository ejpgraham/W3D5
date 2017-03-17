require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'

module Searchable
  def where(params)
    values1 = params.values
    where_line = params.keys.map do |key|
      "#{key} = ?"
    end
    where_line = where_line.join(" AND ")
    # debugger

    #
    results = DBConnection.execute(<<-SQL, *values1)
       SELECT
       *
       FROM
       #{self.table_name}
       WHERE
       #{where_line}

    SQL

    self.parse_all(results)

  end

end

class SQLObject
  extend Searchable
end
