#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

require 'sequel'
require 'logger'

DB = Sequel.connect($connection_string)

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

%w[app owner environment key value maps].each { |f| require "app/model/#{f}" }

