#   Copyright 2009 ThoughtWorks
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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

