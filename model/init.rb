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

# SQLite is the default database - require ruby sqlite3 libs
DB = Sequel.connect("sqlite:///#{__DIR__}/../escape.db")

# MySQL - requires ruby mysql client
#DB = Sequel.mysql('escape', :user => 'root', :password => '', :host => 'localhost')

# Postgres - requires ruby postgres client
# NOTE: Currently broken due to auto increment issues in Sequel 2.10.0
#DB = Sequel.connect('postgres://esc:password@localhost/escape')

# Oracle - requires ruby-oci8 gem
# NOTE: Currently broken due to auto increment issues in Sequel 2.10.0
#DB = Sequel.connect('oracle://escape:escape@localhost/XE')

# Uncomment line below to turn on SQL debugging
#DB.loggers << Logger.new($stdout)

module EscData
    def EscData.init_model(model)
        if model.table_exists?
            # TODO: Schema upgrade stuff
        else
            model.create_table
        end
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

