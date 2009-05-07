require 'java'
Sequel.require 'adapters/utils/stored_procedures'

module Sequel
  # Houses Sequel's JDBC support when running on JRuby.
  # Support for individual database types is done using sub adapters.
  # PostgreSQL, MySQL, SQLite, Oracle, and MSSQL all have relatively good support,
  # close the the level supported by the native adapter.
  # PostgreSQL, MySQL, SQLite can load necessary support using
  # the jdbc-* gem, if it is installed, though they will work if you
  # have the correct .jar in your CLASSPATH.  Oracle and MSSQL should
  # load the necessary support if you have the .jar in your CLASSPATH.
  # For all other databases, the Java class should be loaded manually
  # before calling Sequel.connect.
  #
  # Note that when using a JDBC adapter, the best way to use Sequel
  # is via Sequel.connect, NOT Sequel.jdbc.  Use the JDBC connection
  # string when connecting, which will be in a different format than
  # the native connection string.  The connection string should start
  # with 'jdbc:'.  For PostgreSQL, use 'jdbc:postgresql:', and for
  # SQLite you do not need 2 preceding slashes for the database name
  # (use no preceding slashes for a relative path, and one preceding
  # slash for an absolute path).
  module JDBC
    # Make it accesing the java.lang hierarchy more ruby friendly.
    module JavaLang
      include_package 'java.lang'
    end
    
    # Make it accesing the java.sql hierarchy more ruby friendly.
    module JavaSQL
      include_package 'java.sql'
    end
    
    # Contains procs keyed on sub adapter type that extend the
    # given database object so it supports the correct database type.
    DATABASE_SETUP = {:postgresql=>proc do |db|
        Sequel.require 'adapters/jdbc/postgresql'
        db.extend(Sequel::JDBC::Postgres::DatabaseMethods)
        JDBC.load_gem('postgres')
        org.postgresql.Driver
      end,
      :mysql=>proc do |db|
        Sequel.require 'adapters/jdbc/mysql'
        db.extend(Sequel::JDBC::MySQL::DatabaseMethods)
        JDBC.load_gem('mysql')
        com.mysql.jdbc.Driver
      end,
      :sqlite=>proc do |db|
        Sequel.require 'adapters/jdbc/sqlite'
        db.extend(Sequel::JDBC::SQLite::DatabaseMethods)
        JDBC.load_gem('sqlite3')
        org.sqlite.JDBC
      end,
      :oracle=>proc do |db|
        Sequel.require 'adapters/jdbc/oracle'
        db.extend(Sequel::JDBC::Oracle::DatabaseMethods)
        Java::oracle.jdbc.driver.OracleDriver
      end,
      :sqlserver=>proc do |db|
        Sequel.require 'adapters/shared/mssql'
        db.extend(Sequel::MSSQL::DatabaseMethods)
        com.microsoft.sqlserver.jdbc.SQLServerDriver
      end,
      :h2=>proc do |db|
        Sequel.require 'adapters/jdbc/h2'
        db.extend(Sequel::JDBC::H2::DatabaseMethods)
        JDBC.load_gem('h2')
        org.h2.Driver
      end
    }
    
    # Allowing loading the necessary JDBC support via a gem, which
    # works for PostgreSQL, MySQL, and SQLite.
    def self.load_gem(name)
      begin
        require "jdbc/#{name}"
      rescue LoadError
        # jdbc gem not used, hopefully the user has the .jar in their CLASSPATH
      end
    end

    # JDBC Databases offer a fairly uniform interface that does not change
    # much based on the sub adapter.
    class Database < Sequel::Database
      set_adapter_scheme :jdbc
      
      # The type of database we are connecting to
      attr_reader :database_type
      
      # Call the DATABASE_SETUP proc directly after initialization,
      # so the object always uses sub adapter specific code.  Also,
      # raise an error immediately if the connection doesn't have a
      # uri, since JDBC requires one.
      def initialize(opts)
        @opts = opts
        raise(Error, "No connection string specified") unless uri
        if match = /\Ajdbc:([^:]+)/.match(uri) and prok = DATABASE_SETUP[match[1].to_sym]
          prok.call(self)
        end
        super(opts)
      end
      
      # Execute the given stored procedure with the give name. If a block is
      # given, the stored procedure should return rows.
      def call_sproc(name, opts = {})
        args = opts[:args] || []
        sql = "{call #{name}(#{args.map{'?'}.join(',')})}"
        synchronize(opts[:server]) do |conn|
          cps = conn.prepareCall(sql)

          i = 0
          args.each{|arg| set_ps_arg(cps, arg, i+=1)}

          begin
            if block_given?
              yield cps.executeQuery
            else
              case opts[:type]
              when :insert
                cps.executeUpdate
                last_insert_id(conn, opts)
              else
                cps.executeUpdate
              end
            end
          rescue NativeException, JavaSQL::SQLException => e
            raise_error(e)
          ensure
            cps.close
          end
        end
      end
      
      # Connect to the database using JavaSQL::DriverManager.getConnection.
      def connect(server)
        setup_connection(JavaSQL::DriverManager.getConnection(uri(server_opts(server))))
      end
      
      # Return instances of JDBC::Dataset with the given opts.
      def dataset(opts = nil)
        JDBC::Dataset.new(self, opts)
      end
      
      # Execute the given SQL.  If a block is given, if should be a SELECT
      # statement or something else that returns rows.
      def execute(sql, opts={}, &block)
        return call_sproc(sql, opts, &block) if opts[:sproc]
        return execute_prepared_statement(sql, opts, &block) if [Symbol, Dataset].any?{|c| sql.is_a?(c)}
        log_info(sql)
        synchronize(opts[:server]) do |conn|
          stmt = conn.createStatement
          begin
            if block_given?
              yield stmt.executeQuery(sql)
            else
              case opts[:type]
              when :ddl
                stmt.execute(sql)
              when :insert
                stmt.executeUpdate(sql)
                last_insert_id(conn, opts)
              else
                stmt.executeUpdate(sql)
              end
            end
          rescue NativeException, JavaSQL::SQLException => e
            raise_error(e)
          ensure
            stmt.close
          end
        end
      end
      alias execute_dui execute
      
      # Execute the given DDL SQL, which should not return any
      # values or rows.
      def execute_ddl(sql, opts={})
        execute(sql, {:type=>:ddl}.merge(opts))
      end
      
      # Execute the given INSERT SQL, returning the last inserted
      # row id.
      def execute_insert(sql, opts={})
        execute(sql, {:type=>:insert}.merge(opts))
      end
      
      # All tables in this database
      def tables
        ts = []
        ds = dataset
        metadata(:getTables, nil, nil, nil, ['TABLE'].to_java(:string)){|h| ts << ds.send(:output_identifier, h[:table_name])}
        ts
      end
      
      # Default transaction method that should work on most JDBC
      # databases.  Does not use the JDBC transaction methods, uses
      # SQL BEGIN/ROLLBACK/COMMIT statements instead.
      def transaction(opts={})
        unless opts.is_a?(Hash)
          Deprecation.deprecate('Passing an argument other than a Hash to Database#transaction', "Use DB.transaction(:server=>#{opts.inspect})") 
          opts = {:server=>opts}
        end
        synchronize(opts[:server]) do |conn|
          return yield(conn) if @transactions.include?(Thread.current)
          stmt = conn.createStatement
          begin
            log_info(begin_transaction_sql)
            stmt.execute(begin_transaction_sql)
            @transactions << Thread.current
            yield(conn)
          rescue Exception => e
            log_info(rollback_transaction_sql)
            stmt.execute(rollback_transaction_sql)
            transaction_error(e)
          ensure
            unless e
              log_info(commit_transaction_sql)
              stmt.execute(commit_transaction_sql)
            end
            stmt.close
            @transactions.delete(Thread.current)
          end
        end
      end
      
      # The uri for this connection.  You can specify the uri
      # using the :uri, :url, or :database options.  You don't
      # need to worry about this if you use Sequel.connect
      # with the JDBC connectrion strings.
      def uri(opts={})
        opts = @opts.merge(opts)
        ur = opts[:uri] || opts[:url] || opts[:database]
        ur =~ /^\Ajdbc:/ ? ur : "jdbc:#{ur}"
      end
      
      private
      
      # The JDBC adapter should not need the pool to convert exceptions.
      def connection_pool_default_options
        super.merge(:pool_convert_exceptions=>false)
      end
      
      # Close given adapter connections
      def disconnect_connection(c)
        c.close
      end
      
      # Execute the prepared statement.  If the provided name is a
      # dataset, use that as the prepared statement, otherwise use
      # it as a key to look it up in the prepared_statements hash.
      # If the connection we are using has already prepared an identical
      # statement, use that statement instead of creating another.
      # Otherwise, prepare a new statement for the connection, bind the
      # variables, and execute it.
      def execute_prepared_statement(name, opts={})
        args = opts[:arguments]
        if Dataset === name
          ps = name
          name = ps.prepared_statement_name
        else
          ps = prepared_statements[name]
        end
        sql = ps.prepared_sql
        synchronize(opts[:server]) do |conn|
          if name and cps = conn.prepared_statements[name] and cps[0] == sql
            cps = cps[1]
          else
            if cps
              log_info("Closing #{name}")
              cps[1].close
            end
            log_info("Preparing#{" #{name}:" if name} #{sql}")
            cps = conn.prepareStatement(sql)
            conn.prepared_statements[name] = [sql, cps] if name
          end
          i = 0
          args.each{|arg| set_ps_arg(cps, arg, i+=1)}
          log_info("Executing#{" #{name}" if name}", args)
          begin
            if block_given?
              yield cps.executeQuery
            else
              case opts[:type]
              when :ddl
                cps.execute
              when :insert
                cps.executeUpdate
                last_insert_id(conn, opts)
              else
                cps.executeUpdate
              end
            end
          rescue NativeException, JavaSQL::SQLException => e
            raise_error(e)
          ensure
            cps.close unless name
          end
        end
      end
      
      # By default, there is no support for determining the last inserted
      # id, so return nil.  This method should be overridden in
      # sub adapters.
      def last_insert_id(conn, opts)
        nil
      end
      
      # Yield the metadata for this database
      def metadata(*args, &block)
        ds = dataset
        ds.identifier_output_method = :downcase
        synchronize{|c| ds.send(:process_result_set, c.getMetaData.send(*args), &block)}
      end
      
      # Java being java, you need to specify the type of each argument
      # for the prepared statement, and bind it individually.  This
      # guesses which JDBC method to use, and hopefully JRuby will convert
      # things properly for us.
      def set_ps_arg(cps, arg, i)
        case arg
        when Integer
          cps.setInt(i, arg)
        when String
          cps.setString(i, arg)
        when Date, Java::JavaSql::Date
          cps.setDate(i, arg)
        when Time, DateTime, Java::JavaSql::Timestamp
          cps.setTimestamp(i, arg)
        when Float
          cps.setDouble(i, arg)
        when nil
          cps.setNull(i, JavaSQL::Types::NULL)
        end
      end
      
      # Add a prepared_statements accessor to the connection,
      # and set it to an empty hash.  This is used to store
      # adapter specific prepared statements.
      def setup_connection(conn)
        class << conn
          attr_accessor :prepared_statements
        end
        conn.prepared_statements = {}
        conn
      end
      
      # All tables in this database
      def schema_parse_table(table, opts={})
        ds = dataset
        schema, table = schema_and_table(table)
        schema = ds.send(:input_identifier, schema) if schema
        table = ds.send(:input_identifier, table)
        pks, ts = [], []
        metadata(:getPrimaryKeys, nil, schema, table) do |h|
          pks << h[:column_name]
        end
        metadata(:getColumns, nil, schema, table, nil) do |h|
          ts << [ds.send(:output_identifier, h[:column_name]), {:type=>schema_column_type(h[:type_name]), :db_type=>h[:type_name], :default=>(h[:column_def] == '' ? nil : h[:column_def]), :allow_null=>(h[:nullable] != 0), :primary_key=>pks.include?(h[:column_name])}]
        end
        ts
      end
    end
    
    class Dataset < Sequel::Dataset
      include StoredProcedures
      
      # Use JDBC PreparedStatements instead of emulated ones.  Statements
      # created using #prepare are cached at the connection level to allow
      # reuse.  This also supports bind variables by using unnamed
      # prepared statements created using #call.
      module PreparedStatementMethods
        include Sequel::Dataset::UnnumberedArgumentMapper
        
        private
        
        # Execute the prepared SQL using the stored type and
        # arguments derived from the hash passed to call.
        def execute(sql, opts={}, &block)
          super(self, {:arguments=>bind_arguments, :type=>sql_query_type}.merge(opts), &block)
        end
        
        # Same as execute, explicit due to intricacies of alias and super.
        def execute_dui(sql, opts={}, &block)
          super(self, {:arguments=>bind_arguments, :type=>sql_query_type}.merge(opts), &block)
        end
        
        # Same as execute, explicit due to intricacies of alias and super.
        def execute_insert(sql, opts={}, &block)
          super(self, {:arguments=>bind_arguments, :type=>sql_query_type}.merge(opts), &block)
        end
      end
      
      # Use JDBC CallableStatements to execute stored procedures.  Only supported
      # if the underlying database has stored procedure support.
      module StoredProcedureMethods
        include Sequel::Dataset::StoredProcedureMethods
        
        private
        
        # Execute the database stored procedure with the stored arguments.
        def execute(sql, opts={}, &block)
          super(@sproc_name, {:args=>@sproc_args, :sproc=>true, :type=>sql_query_type}.merge(opts), &block)
        end
        
        # Same as execute, explicit due to intricacies of alias and super.
        def execute_dui(sql, opts={}, &block)
          super(@sproc_name, {:args=>@sproc_args, :sproc=>true, :type=>sql_query_type}.merge(opts), &block)
        end
        
        # Same as execute, explicit due to intricacies of alias and super.
        def execute_insert(sql, opts={}, &block)
          super(@sproc_name, {:args=>@sproc_args, :sproc=>true, :type=>sql_query_type}.merge(opts), &block)
        end
      end
      
      # Correctly return rows from the database and return them as hashes.
      def fetch_rows(sql, &block)
        execute(sql){|result| process_result_set(result, &block)}
        self
      end
      
      # Create a named prepared statement that is stored in the
      # database (and connection) for reuse.
      def prepare(type, name=nil, values=nil)
        ps = to_prepared_statement(type, values)
        ps.extend(PreparedStatementMethods)
        if name
          ps.prepared_statement_name = name
          db.prepared_statements[name] = ps
        end
        ps
      end
      
      private
      
      # Convert the type.  Used for converting Java types to ruby types.
      def convert_type(v)
        case v
        when Java::JavaSQL::Timestamp, Java::JavaSQL::Time
          Sequel.string_to_datetime(v.to_string)
        when Java::JavaSQL::Date
          Sequel.string_to_date(v.to_string)
        when Java::JavaIo::BufferedReader
          lines = []
          while(line = v.read_line) do lines << line end
          lines.join("\n")
        when Java::JavaMath::BigDecimal
          BigDecimal.new(v.to_string)
        else
          v
        end
      end
      
      # Extend the dataset with the JDBC stored procedure methods.
      def prepare_extend_sproc(ds)
        ds.extend(StoredProcedureMethods)
      end
      
      # Split out from fetch rows to allow processing of JDBC result sets
      # that don't come from issuing an SQL string.
      def process_result_set(result)
        # get column names
        meta = result.getMetaData
        column_count = meta.getColumnCount
        @columns = []
        column_count.times{|i| @columns << output_identifier(meta.getColumnLabel(i+1))}

        # get rows
        while result.next
          row = {}
          @columns.each_with_index{|v, i| row[v] = convert_type(result.getObject(i+1))}
          yield row
        end
      end
    end
  end
end

class Java::JavaSQL::Timestamp
  # Add a usec method in order to emulate Time values.
  def usec
    Deprecation.deprecate('Java::JavaSQL::Timestamp#usec', 'Use timestamp.getNanos/1000')
    getNanos/1000
  end
end
