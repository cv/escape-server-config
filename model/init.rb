# Here goes your database connection and options:

require 'sequel'

DB = Sequel.connect("sqlite:///#{__DIR__}/../escape.db")

def init_model(model)
    if model.table_exists?
        DB[model.table_name].update_sql
    else
        model.create_table! 
    end
end

# Here go your requires for models:
# require 'model/user'

require 'model/app'
require 'model/environment'
require 'model/owner'
require 'model/value'

