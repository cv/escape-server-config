# Here goes your database connection and options:

require 'sequel'
require 'logger'

DB = Sequel.connect("sqlite:///#{__DIR__}/../escape.db")
# Uncomment line below to turn on SQL debugging
#DB.loggers << Logger.new($stdout)

module EscData
    def EscData.init_model(model)
        if model.table_exists?
            DB[model.table_name].update_sql
        else
            model.create_table! 
        end
    end

    def EscData.setup_statics
    end

end

# Here go your requires for models:
# require 'model/user'

require 'model/app'
require 'model/environment'
require 'model/owner'
require 'model/key'
require 'model/value'
require 'model/maps'

EscData.setup_statics

