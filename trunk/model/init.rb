# Here goes your database connection and options:

require 'sequel'

DB = Sequel.connect("sqlite:///#{__DIR__}/../escape.db")

def init_model(model)
    model.create_table! unless model.table_exists?
end

# Here go your requires for models:
# require 'model/user'

require 'model/app'
require 'model/environment'
require 'model/owner'
require 'model/value'

# Update the databases if needed
DB.tables.each { |table|
    DB[table].update_sql
}

