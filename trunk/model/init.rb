# Here goes your database connection and options:

require 'sequel'

DB = Sequel.connect("sqlite:///#{__DIR__}/escape.db")

# Here go your requires for models:
# require 'model/user'

require 'model/app'
require 'model/environment'
require 'model/owner'
require 'model/value'

