Sequel.require 'adapters/utils/unsupported'

module Sequel
  module SQLite
    module DatabaseMethods
      AUTO_VACUUM = [:none, :full, :incremental].freeze
      SYNCHRONOUS = [:off, :normal, :full].freeze
      TABLES_FILTER = "type = 'table' AND NOT name = 'sqlite_sequence'"
      TEMP_STORE = [:default, :file, :memory].freeze
      TYPES = Sequel::Database::TYPES.merge(Bignum=>'integer')
      
      # Run all alter_table commands in a transaction.  This is technically only
      # needed for drop column.
      def alter_table(name, generator=nil, &block)
        transaction{super}
      end

      # A symbol signifying the value of the auto_vacuum PRAGMA.
      def auto_vacuum
        AUTO_VACUUM[pragma_get(:auto_vacuum).to_i]
      end
      
      # Set the auto_vacuum PRAGMA using the given symbol (:none, :full, or
      # :incremental).
      def auto_vacuum=(value)
        value = AUTO_VACUUM.index(value) || (raise Error, "Invalid value for auto_vacuum option. Please specify one of :none, :full, :incremental.")
        pragma_set(:auto_vacuum, value)
      end
      
      # Get the value of the given PRAGMA.
      def pragma_get(name)
        self["PRAGMA #{name}"].single_value
      end
      
      # Set the value of the given PRAGMA to value.
      def pragma_set(name, value)
        execute_ddl("PRAGMA #{name} = #{value}")
      end
      
      # A symbol signifying the value of the synchronous PRAGMA.
      def synchronous
        SYNCHRONOUS[pragma_get(:synchronous).to_i]
      end
      
      # Set the synchronous PRAGMA using the given symbol (:off, :normal, or :full).
      def synchronous=(value)
        value = SYNCHRONOUS.index(value) || (raise Error, "Invalid value for synchronous option. Please specify one of :off, :normal, :full.")
        pragma_set(:synchronous, value)
      end
      
      # Array of symbols specifying the table names in the current database.
      #
      # Options:
      # * :server - Set the server to use.
      def tables(opts={})
        ds = self[:sqlite_master].server(opts[:server]).filter(TABLES_FILTER)
        ds.identifier_output_method = nil
        ds.identifier_input_method = nil
        ds2 = dataset
        ds.map{|r| ds2.send(:output_identifier, r[:name])}
      end
      
      # A symbol signifying the value of the temp_store PRAGMA.
      def temp_store
        TEMP_STORE[pragma_get(:temp_store).to_i]
      end
      
      # Set the temp_store PRAGMA using the given symbol (:default, :file, or :memory).
      def temp_store=(value)
        value = TEMP_STORE.index(value) || (raise Error, "Invalid value for temp_store option. Please specify one of :default, :file, :memory.")
        pragma_set(:temp_store, value)
      end
      
      private

      # SQLite supports limited table modification.  You can add a column
      # or an index.  Dropping columns is supported by copying the table into
      # a temporary table, dropping the table, and creating a new table without
      # the column inside of a transaction.
      def alter_table_sql(table, op)
        case op[:op]
        when :add_column, :add_index, :drop_index
          super
        when :drop_column
          qt = quote_schema_table(table)
          bt = quote_identifier(backup_table_name(qt.gsub('`', '')))
          columns_str = dataset.send(:identifier_list, columns_for(table, :except => op[:name]))
          defined_columns_str = column_list_sql(defined_columns_for(table, :except => op[:name]))
          ["CREATE TEMPORARY TABLE #{bt}(#{defined_columns_str})",
           "INSERT INTO #{bt} SELECT #{columns_str} FROM #{qt}",
           "DROP TABLE #{qt}",
           "CREATE TABLE #{qt}(#{defined_columns_str})",
           "INSERT INTO #{qt} SELECT #{columns_str} FROM #{bt}",
           "DROP TABLE #{bt}"]
        when :rename_column
          qt = quote_schema_table(table)
          bt = quote_identifier(backup_table_name(qt.gsub('`', '')))
          old_columns = dataset.send(:identifier_list, columns_for(table))
          new_columns_arr = columns_for(table)

          # Replace the old column in place. This is extremely important.
          new_columns_arr[new_columns_arr.index(op[:name])] = op[:new_name]
          
          new_columns = dataset.send(:identifier_list, new_columns_arr)
          
          def_old_columns = column_list_sql(defined_columns_for(table))

          def_new_columns_arr = defined_columns_for(table).map do |c|
            c[:name] = op[:new_name].to_s if c[:name] == op[:name].to_s
            c
          end
          
          def_new_columns = column_list_sql(def_new_columns_arr)

          [
           "CREATE TEMPORARY TABLE #{bt}(#{def_old_columns})",
           "INSERT INTO #{bt}(#{old_columns}) SELECT #{old_columns} FROM #{qt}",
           "DROP TABLE #{qt}",
           "CREATE TABLE #{qt}(#{def_new_columns})",
           "INSERT INTO #{qt}(#{new_columns}) SELECT #{old_columns} FROM #{bt}",
           "DROP TABLE #{bt}"
          ]

        else
          raise Error, "Unsupported ALTER TABLE operation"
        end
      end
      
      # The array of column symbols in the table, except for ones given in opts[:except]
      def backup_table_name(table, opts={})
        (opts[:times]||1000).times do |i|
          table_name = "#{table}_backup#{i}"
          return table_name unless table_exists?(table_name)
        end
      end

      # The array of column symbols in the table, except for ones given in opts[:except]
      def columns_for(table, opts={})
        cols = schema_parse_table(table, {}).map{|c| c[0]}
        cols = cols - Array(opts[:except])
        cols
      end

      # The array of column schema hashes, except for the ones given in opts[:except]
      def defined_columns_for(table, opts={})
        cols = parse_pragma(table, {})
        cols.each{|c| c[:default] = LiteralString.new(c[:default]) if c[:default]}
        if opts[:except]
          nono= Array(opts[:except]).compact.map{|n| n.to_s}
          cols.reject!{|c| nono.include? c[:name] }
        end
        cols
      end
      
      # SQLite folds unquoted identifiers to lowercase, so it shouldn't need to upcase identifiers on input.
      def identifier_input_method_default
        nil
      end
      
      # SQLite folds unquoted identifiers to lowercase, so it shouldn't need to upcase identifiers on output.
      def identifier_output_method_default
        nil
      end

      # Parse the output of the table_info pragma
      def parse_pragma(table_name, opts)
        ds2 = dataset
        ds = self["PRAGMA table_info(?)", ds2.send(:input_identifier, table_name)]
        ds.identifier_output_method = nil
        ds.map do |row|
          row.delete(:cid)
          row[:allow_null] = row.delete(:notnull).to_i == 0
          row[:default] = row.delete(:dflt_value)
          row[:primary_key] = row.delete(:pk).to_i == 1
          row[:default] = nil if blank_object?(row[:default])
          row[:db_type] = row.delete(:type)
          row[:type] = schema_column_type(row[:db_type])
          row
        end
      end
      
      # SQLite supports schema parsing using the table_info PRAGMA, so
      # parse the output of that into the format Sequel expects.
      def schema_parse_table(table_name, opts)
        ds = dataset
        parse_pragma(table_name, opts).map do |row|
          [ds.send(:output_identifier, row.delete(:name)), row]
        end
      end
      
      # Override the standard type conversions with SQLite specific ones
      def type_literal_base(column)
        TYPES[column[:type]]
      end
    end
    
    # Instance methods for datasets that connect to an SQLite database
    module DatasetMethods
      include Dataset::UnsupportedIntersectExceptAll
      include Dataset::UnsupportedIsTrue

      # SQLite does not support pattern matching via regular expressions.
      # SQLite is case insensitive (depending on pragma), so use LIKE for
      # ILIKE.
      def complex_expression_sql(op, args)
        case op
        when :~, :'!~', :'~*', :'!~*'
          raise Error, "SQLite does not support pattern matching via regular expressions"
        when :LIKE, :'NOT LIKE', :ILIKE, :'NOT ILIKE'
          # SQLite is case insensitive for ASCII, and non case sensitive for other character sets
          "#{'NOT ' if [:'NOT LIKE', :'NOT ILIKE'].include?(op)}(#{literal(args.at(0))} LIKE #{literal(args.at(1))})"
        else
          super(op, args)
        end
      end
      
      # SQLite performs a TRUNCATE style DELETE if no filter is specified.
      # Since we want to always return the count of records, add a condition
      # that is always true and then delete.
      def delete(opts = (defarg=true;{}))
        # check if no filter is specified
        if defarg
          @opts[:where] ? super() : filter(1=>1).delete
        else
          opts = @opts.merge(opts)
          super(opts[:where] ? opts : opts.merge(:where=>{1=>1}))
        end
      end
      
      # Insert the values into the database.
      def insert(*values)
        execute_insert(insert_sql(*values))
      end
      
      # Allow inserting of values directly from a dataset.
      def insert_sql(*values)
        if (values.size == 1) && values.first.is_a?(Sequel::Dataset)
          "INSERT INTO #{source_list(@opts[:from])} #{values.first.sql};"
        else
          super(*values)
        end
      end
      
      # SQLite uses the nonstandard ` (backtick) for quoting identifiers.
      def quoted_identifier(c)
        "`#{c}`"
      end
      
      private

      def literal_blob(v)
        blob = ''
        v.each_byte{|x| blob << sprintf('%02x', x)}
        "X'#{blob}'"
      end
      
      # SQLite uses string literals instead of identifiers in AS clauses.
      def as_sql(expression, aliaz)
        "#{expression} AS #{literal(aliaz.to_s)}"
      end
    end
  end
end
