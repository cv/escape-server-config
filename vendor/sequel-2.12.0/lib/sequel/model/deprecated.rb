Sequel.require %w'deprecated_hooks deprecated_validations deprecated_inflector', 'model'

module Sequel
  class Model
    module Validation
      Errors = Model::Errors
    end
    module ClassMethods
      {:size=>:count, :uniq=>:distinct}.each do |o, n|
        class_eval "def #{o}(*args, &block); Deprecation.deprecate('Sequel::Model.#{o}', 'Use Sequel::Model.dataset.#{n}'); dataset.#{n}(*args, &block); end"
      end
  
      def is(*args, &block)
        Deprecation.deprecate('Sequel::Model.is', 'Use Sequel::Model.plugin')
        plugin(*args, &block)
      end
  
      def is_a(*args, &block)
        Deprecation.deprecate('Sequel::Model.is_a', 'Use Sequel::Model.plugin')
        plugin(*args, &block)
      end
  
      def delete_all
        Deprecation.deprecate('Sequel::Model.delete_all', 'Use Sequel::Model.delete')
        dataset.delete
      end
  
      def destroy_all
        Deprecation.deprecate('Sequel::Model.destroy_all', 'Use Sequel::Model.destroy')
        dataset.destroy
      end
  
      def str_columns
        Deprecation.deprecate('Sequel::Model.str_columns', 'Use model.columns.map{|x| x.to_s}')
        @str_columns ||= columns.map{|c| c.to_s.freeze}
      end
  
      def set_sti_key(key)
        Deprecation.deprecate('Sequel::Model.set_sti_key', 'Use Model.plugin(:single_table_inheritance, key)')
        plugin :single_table_inheritance, key
      end
  
      def sti_key
        Deprecation.deprecate('Sequel::Model.sti_key', 'Use Model.plugin(:single_table_inheritance, key) first')
        @sti_key
      end
  
      def sti_dataset
        Deprecation.deprecate('Sequel::Model.sti_dataset', 'Use Model.plugin(:single_table_inheritance, key) first')
        @sti_dataset
      end
  
      def set_cache_ttl(ttl)
        Deprecation.deprecate('Sequel::Model.set_cache_ttl', 'Use Model.plugin(:caching, store, opts) first')
        @cache_ttl = ttl
      end
  
      def set_cache(store, opts = {})
        Deprecation.deprecate('Sequel::Model.set_cache', 'Use Model.plugin(:caching, store, opts)')
        plugin :caching, store, opts
      end

      # Creates table, using the column information from set_schema.
      def create_table
        Deprecation.deprecate('Sequel::Model.create_table', 'Use Model.plugin(:schema) first')
        db.create_table(table_name, :generator=>@schema)
        @db_schema = get_db_schema(true)
        columns
      end
  
      # Drops the table if it exists and then runs create_table.  Should probably
      # not be used except in testing.
      def create_table!
        Deprecation.deprecate('Sequel::Model.create_table!', 'Use Model.plugin(:schema) first')
        drop_table rescue nil 
        create_table
      end
  
      # Drops table.
      def drop_table
        Deprecation.deprecate('Sequel::Model.drop_table', 'Use Model.plugin(:schema) first')
        db.drop_table(table_name)
      end
  
      # Returns table schema created with set_schema for direct descendant of Model.
      # Does not retreive schema information from the database, see db_schema if you
      # want that.
      def schema
        Deprecation.deprecate('Sequel::Model.schema', 'Use Model.plugin(:schema) first')
        @schema || (superclass.schema unless superclass == Model)
      end
  
      # Defines a table schema (see Schema::Generator for more information).
      #
      # This is only needed if you want to use the create_table/create_table! methods.
      # Will also set the dataset if you provide a name, as well as setting
      # the primary key if you defined one in the passed block.
      #
      # In general, it is a better idea to use migrations for production code, as
      # migrations allow changes to existing schema.  set_schema is mostly useful for
      # test code or simple examples.
      def set_schema(name = nil, &block)
        Deprecation.deprecate('Sequel::Model.set_schema', 'Use Model.plugin(:schema) first')
        set_dataset(db[name]) if name
        @schema = Sequel::Schema::Generator.new(db, &block)
        set_primary_key(@schema.primary_key_name) if @schema.primary_key_name
      end
  
      # Returns true if table exists, false otherwise.
      def table_exists?
        Deprecation.deprecate('Sequel::Model.table_exists?', 'Use Model.plugin(:schema) first')
        db.table_exists?(table_name)
      end

      def serialize(*columns)
        Deprecation.deprecate('Sequel::Model.serialize', 'A implementation that doesn\'t use dataset transforms can be added via plugin(:serialization, (:marshal||:yaml), column1, column2)')
        format = extract_options!(columns)[:format] || :yaml
        @transform = columns.inject({}) do |m, c|
          m[c] = format
          m
        end
        @dataset.transform(@transform) if @dataset
      end

      def serialized?(column)
        @transform ? @transform.include?(column) : false
      end
    end
  
    module InstanceMethods
      def dataset
        Deprecation.deprecate('Sequel::Model#dataset', 'Use model_object.model.dataset')
        model.dataset
      end
  
      def save!(*args)
        Deprecation.deprecate('Sequel::Model#save!', 'Use model_object.save(..., :validate=>false)')
        opts = args.last.is_a?(Hash) ? args.pop : {}
        args.push(opts.merge(:validate=>false))
        save(*args)
      end
  
      def str_columns
        Deprecation.deprecate('Sequel::Model#str_columns', 'Use model_object.columns.map{|x| x.to_s}')
        model.str_columns
      end
  
      def set_with_params(hash)
        Deprecation.deprecate('Sequel::Model#set_with_params', 'Use Sequel::Model#set')
        set_restricted(hash, nil, nil)
      end
  
      def update_with_params(hash)
        Deprecation.deprecate('Sequel::Model#update_with_params', 'Use Sequel::Model#update')
        update_restricted(hash, nil, nil)
      end
  
      def set_values(values)
        Deprecation.deprecate('Sequel::Model#set_values', 'Use Sequel::Model#set')
        s = str_columns
        vals = values.inject({}) do |m, kv|
          k, v = kv
          k = case k
          when Symbol
            k
          when String
            raise(Error, "all string keys must be a valid columns") unless s.include?(k)
            k.to_sym
          else
            raise(Error, "Only symbols and strings allows as keys")
          end
          m[k] = v
          m
        end
        vals.each {|k, v| @values[k] = v}
        vals
      end
  
      def update_values(values)
        Deprecation.deprecate('Sequel::Model#update_values', 'Use Sequel::Model#update or model_object.this.update')
        this.update(set_values(values))
      end
    end

    if defined?(Associations::ClassMethods)
      module Associations::ClassMethods
        def belongs_to(*args, &block)
          Deprecation.deprecate('Sequel::Model.belongs_to', 'Use Sequel::Model.many_to_one')
          many_to_one(*args, &block)
        end

        def has_many(*args, &block)
          Deprecation.deprecate('Sequel::Model.has_many', 'Use Sequel::Model.one_to_many')
          one_to_many(*args, &block)
        end

        def has_and_belongs_to_many(*args, &block)
          Deprecation.deprecate('Sequel::Model.has_and_belongs_to_many', 'Use Sequel::Model.many_to_many')
          many_to_many(*args, &block)
        end
      end
    end
  end
end
