module Sequel
  class Dataset
    COMMA_SEPARATOR = ', '.freeze
    COUNT_OF_ALL_AS_COUNT = SQL::Function.new(:count, LiteralString.new('*'.freeze)).as(:count)

    # Returns the first record matching the conditions. Examples:
    #
    #   ds[:id=>1] => {:id=1}
    def [](*conditions)
      Deprecation.deprecate('Using an Integer argument to Dataset#[] is deprecated and will raise an error in Sequel 3.0. Use Dataset#first.') if conditions.length == 1 and conditions.is_a?(Integer)
      Deprecation.deprecate('Using Dataset#[] without an argument is deprecated and will raise an error in Sequel 3.0. Use Dataset#first.') if conditions.length == 0
      first(*conditions)
    end

    # Update all records matching the conditions
    # with the values specified. Examples:
    #
    #   ds[:id=>1] = {:id=>2} # SQL: UPDATE ... SET id = 2 WHERE id = 1
    def []=(conditions, values)
      filter(conditions).update(values)
    end

    # Returns the average value for the given column.
    def avg(column)
      get{|o| o.avg(column)}
    end
    
    # Returns true if no records exist in the dataset, false otherwise
    def empty?
      get(1).nil?
    end
    
    # If a integer argument is
    # given, it is interpreted as a limit, and then returns all 
    # matching records up to that limit.  If no argument is passed,
    # it returns the first matching record.  If any other type of
    # argument(s) is passed, it is given to filter and the
    # first matching record is returned. If a block is given, it is used
    # to filter the dataset before returning anything.  Examples:
    # 
    #   ds.first => {:id=>7}
    #   ds.first(2) => [{:id=>6}, {:id=>4}]
    #   ds.order(:id).first(2) => [{:id=>1}, {:id=>2}]
    #   ds.first(:id=>2) => {:id=>2}
    #   ds.first("id = 3") => {:id=>3}
    #   ds.first("id = ?", 4) => {:id=>4}
    #   ds.first{|o| o.id > 2} => {:id=>5}
    #   ds.order(:id).first{|o| o.id > 2} => {:id=>3}
    #   ds.first{|o| o.id > 2} => {:id=>5}
    #   ds.first("id > ?", 4){|o| o.id < 6} => {:id=>5}
    #   ds.order(:id).first(2){|o| o.id < 2} => [{:id=>1}]
    def first(*args, &block)
      ds = block ? filter(&block) : self

      if args.empty?
        ds.single_record
      else
        args = (args.size == 1) ? args.first : args
        if Integer === args
          ds.limit(args).all
        else
          ds.filter(args).single_record
        end
      end
    end

    # Return the column value for the first matching record in the dataset.
    # Raises an error if both an argument and block is given.
    #
    #   ds.get(:id)
    #   ds.get{|o| o.sum(:id)}
    def get(column=nil, &block)
      raise(Error, 'must provide argument or block to Dataset#get, not both') if column && block
      (column ? select(column) : select(&block)).single_value
    end

    # Returns a dataset grouped by the given column with count by group,
    # order by the count of records.  Examples:
    #
    #   ds.group_and_count(:name) => [{:name=>'a', :count=>1}, ...]
    #   ds.group_and_count(:first_name, :last_name) => [{:first_name=>'a', :last_name=>'b', :count=>1}, ...]
    def group_and_count(*columns)
      group(*columns).select(*(columns + [COUNT_OF_ALL_AS_COUNT])).order(:count)
    end
    
    # Inserts multiple records into the associated table. This method can be
    # to efficiently insert a large amounts of records into a table. Inserts
    # are automatically wrapped in a transaction.
    # 
    # This method is called with a columns array and an array of value arrays:
    #
    #   dataset.import([:x, :y], [[1, 2], [3, 4]])
    #
    # This method also accepts a dataset instead of an array of value arrays:
    #
    #   dataset.import([:x, :y], other_dataset.select(:a___x, :b___y))
    #
    # The method also accepts a :slice or :commit_every option that specifies
    # the number of records to insert per transaction. This is useful especially
    # when inserting a large number of records, e.g.:
    #
    #   # this will commit every 50 records
    #   dataset.import([:x, :y], [[1, 2], [3, 4], ...], :slice => 50)
    def import(*args)
      if args.empty?
        Sequel::Deprecation.deprecate('Calling Sequel::Dataset#import with no arguments', 'Use dataset.multi_insert([])')
        return
      elsif args[0].is_a?(Array) && args[1].is_a?(Array)
        columns, values, opts = *args
      elsif args[0].is_a?(Array) && args[1].is_a?(Dataset)
        table = @opts[:from].first
        columns, dataset = *args
        sql = "INSERT INTO #{quote_identifier(table)} (#{identifier_list(columns)}) VALUES #{literal(dataset)}"
        return @db.transaction{execute_dui(sql)}
      else
        Sequel::Deprecation.deprecate('Calling Sequel::Dataset#import with hashes', 'Use Sequel::Dataset#multi_insert')
        return multi_insert(*args)
      end
      # make sure there's work to do
      Sequel::Deprecation.deprecate('Calling Sequel::Dataset#import an empty column array is deprecated and will raise an error in Sequel 3.0.') if columns.empty?
      return if columns.empty? || values.empty?
      
      slice_size = opts && (opts[:commit_every] || opts[:slice])
      
      if slice_size
        values.each_slice(slice_size) do |slice|
          statements = multi_insert_sql(columns, slice)
          @db.transaction(opts){statements.each{|st| execute_dui(st)}}
        end
      else
        statements = multi_insert_sql(columns, values)
        @db.transaction{statements.each{|st| execute_dui(st)}}
      end
    end
    
    # Returns the interval between minimum and maximum values for the given 
    # column.
    def interval(column)
      get{|o| o.max(column) - o.min(column)}
    end

    # Reverses the order and then runs first.  Note that this
    # will not necessarily give you the last record in the dataset,
    # unless you have an unambiguous order.  If there is not
    # currently an order for this dataset, raises an Error.
    def last(*args, &block)
      raise(Error, 'No order specified') unless @opts[:order]
      reverse.first(*args, &block)
    end
    
    # Maps column values for each record in the dataset (if a column name is
    # given), or performs the stock mapping functionality of Enumerable. 
    # Raises an error if both an argument and block are given. Examples:
    #
    #   ds.map(:id) => [1, 2, 3, ...]
    #   ds.map{|r| r[:id] * 2} => [2, 4, 6, ...]
    def map(column=nil, &block)
      Deprecation.deprecate('Using Dataset#map with an argument and a block is deprecated and will raise an error in Sequel 3.0. Use an argument or a block, not both.') if column && block
      if column
        super(){|r| r[column]}
      else
        super(&block)
      end
    end

    # Returns the maximum value for the given column.
    def max(column)
      get{|o| o.max(column)}
    end

    # Returns the minimum value for the given column.
    def min(column)
      get{|o| o.min(column)}
    end

    # This is a front end for import that allows you to submit an array of
    # hashes instead of arrays of columns and values:
    # 
    #   dataset.multi_insert([{:x => 1}, {:x => 2}])
    #
    # Be aware that all hashes should have the same keys if you use this calling method,
    # otherwise some columns could be missed or set to null instead of to default
    # values.
    #
    # You can also use the :slice or :commit_every option that import accepts.
    def multi_insert(*args)
      if args.empty?
        Sequel::Deprecation.deprecate('Calling Sequel::Dataset#multi_insert with no arguments', 'Use dataset.multi_insert([])')
        return
      elsif args[0].is_a?(Array) && (args[1].is_a?(Array) || args[1].is_a?(Dataset))
        Sequel::Deprecation.deprecate('Calling Sequel::Dataset#multi_insert with an array of columns and an array of arrays of values', 'Use Sequel::Dataset#import')
       return import(*args)
      else
        # we assume that an array of hashes is given
        hashes, opts = *args
        return if hashes.empty?
        columns = hashes.first.keys
        # convert the hashes into arrays
        values = hashes.map {|h| columns.map {|c| h[c]}}
      end
      import(columns, values, opts)
    end

    # Returns a Range object made from the minimum and maximum values for the
    # given column.
    def range(column)
      if r = select{|o| [o.min(column).as(:v1), o.max(column).as(:v2)]}.first
        (r[:v1]..r[:v2])
      end
    end
    
    # Returns the first record in the dataset.
    def single_record(opts = (defarg=true;nil))
      Deprecation.deprecate("Calling Dataset#single_record with an argument is deprecated and will raise an error in Sequel 3.0.  Use dataset.clone(opts).single_record.") unless defarg
      ds = clone(:limit=>1)
      opts = opts.merge(:limit=>1) if opts and opts[:limit]
      defarg ? ds.each{|r| return r} : ds.each(opts){|r| return r}
      nil
    end

    # Returns the first value of the first record in the dataset.
    # Returns nil if dataset is empty.
    def single_value(opts = (defarg=true;nil))
      Deprecation.deprecate("Calling Dataset#single_value with an argument is deprecated and will raise an error in Sequel 3.0.  Use dataset.clone(opts).single_value.") unless defarg
      ds = naked.clone(:graph=>false)
      if r = (defarg ? ds.single_record : ds.single_record(opts))
        r.values.first
      end
    end
    
    # Returns the sum for the given column.
    def sum(column)
      get{|o| o.sum(column)}
    end

    # Returns true if the table exists.  Will raise an error
    # if the dataset has fixed SQL or selects from another dataset
    # or more than one table.
    def table_exists?
      raise(Sequel::Error, "this dataset has fixed SQL") if @opts[:sql]
      raise(Sequel::Error, "this dataset selects from multiple sources") if @opts[:from].size != 1
      t = @opts[:from].first
      raise(Sequel::Error, "this dataset selects from a sub query") if t.is_a?(Dataset)
      @db.table_exists?(t)
    end

    # Returns a string in CSV format containing the dataset records. By 
    # default the CSV representation includes the column titles in the
    # first line. You can turn that off by passing false as the 
    # include_column_titles argument.
    #
    # This does not use a CSV library or handle quoting of values in
    # any way.  If any values in any of the rows could include commas or line
    # endings, you shouldn't use this.
    def to_csv(include_column_titles = true)
      n = naked
      cols = n.columns
      csv = ''
      csv << "#{cols.join(COMMA_SEPARATOR)}\r\n" if include_column_titles
      n.each{|r| csv << "#{cols.collect{|c| r[c]}.join(COMMA_SEPARATOR)}\r\n"}
      csv
    end
    
    # Returns a hash with one column used as key and another used as value.
    # If rows have duplicate values for the key column, the latter row(s)
    # will overwrite the value of the previous row(s). If the value_column
    # is not given or nil, uses the entire hash as the value.
    def to_hash(key_column, value_column = nil)
      inject({}) do |m, r|
        m[r[key_column]] = value_column ? r[value_column] : r
        m
      end
    end
  end
end
