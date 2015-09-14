require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns unless @columns.nil?
    table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    columns = table.first
    @columns = columns.map {|col| col.to_sym}

  end

  def self.finalize!

    self.columns.each do |col|
      define_method(col) do
        # instance_variable_get(col) not the case
        attributes[col]
      end

      define_method("#{col}=") do |value|
        # instance_variable_set("@#{col}", value)
        attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    return @table_name unless @table_name.nil?
    self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      (#{self.table_name})

    SQL
    parse_all(results)

  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      (#{self.table_name})
    WHERE
      id = ?
    SQL
    results.empty? ? nil : self.new(results.first)
  end

  def initialize(params = {})
    params.each do |k, v|
      unless self.class.columns.include?(k.to_sym)
        raise "unknown attribute '#{k}'"
      else
        attributes[k.to_sym] = v
      end
    end

    # ...
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    #['id', 'name', 'owner_id']
    self.class.columns.map do |col|
      self.send(col)
    end
  end

  def insert
    col_names = self.class.columns.reject{|x| x == :id}.join(', ')
    question_marks = (["?"] * (attribute_values.length-1)).join(', ')
    query = <<-SQL
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    DBConnection.execute(query, *(attribute_values.drop(1)))

    self.id = DBConnection.last_insert_row_id
  end

  def update
    sets = self.class.columns.map do |col|
      "#{col} = ?"
    end.join(', ')

    DBConnection.execute(<<-SQL, attribute_values, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{sets}
    WHERE
      id = ?
    SQL

  end

  def save
    self.id.nil? ? insert : update
  end
end
