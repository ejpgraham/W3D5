require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @data ||= DBConnection.execute2(<<-SQL)
    SELECT
    *
    FROM
      #{self.table_name}
    SQL

    @data.first.map! {|datum| datum.to_sym}

  end

  def self.finalize!
    columns.each do |column|

      define_method(column) do
        attributes[column]

      end

      define_method("#{column}=") do |new_value|
        attributes[column] = new_value
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name

  end

  def self.table_name
    unless @table_name
      @table_name = self.to_s.tableize
    else
    @table_name
    end

  end

  def self.all


  data = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL

    self.parse_all(data)
  end

  def self.parse_all(results)
    array_of_objects = []
    results.each do |result|
      array_of_objects << self.new(result)
    end
    array_of_objects
  end

  def self.find(id)
    results  = DBConnection.execute(<<-SQL, id )
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      id = ?
    LIMIT
      1
    SQL
  a =  self.parse_all(results)
  a.first


  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_sym = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_sym)

      # self.send(attr_sym)
      self.send("#{attr_name}=", value)

    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    values = self.attributes.values
  end

  def insert
    col_names = self.class.columns[1..-1].join(", ")
    question_marks = (["?"] * (self.class.columns.length - 1)).join(", ")
    col_attributes = self.attribute_values
    # debugger
    DBConnection.execute(<<-SQL, *col_attributes)

    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})

    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update

    cols = self.class.columns[1..-1]
    attribute_vals = self.attribute_values
    attribute_vals = attribute_vals[1..-1]


    cols.map! do |col|
      "#{col} = ?"
    end
    cols = cols.join(", ")
# debugger
    DBConnection.execute(<<-SQL, *attribute_vals, id)

    UPDATE
      #{self.class.table_name}
    SET
      #{cols}
    WHERE
      id = ?
    SQL

  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end 
  end
end
