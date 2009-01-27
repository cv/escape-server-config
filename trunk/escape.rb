#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'sequel'

DB = Sequel.connect("sqlite:///#{__DIR__}/escape.db")

class App < Sequel::Model(:apps)
    set_schema do
        primary_key :id
        text :name
    end
end

class Environment < Sequel::Model(:environments)
    many_to_one :owner
    set_schema do
        primary_key :id
        text :name
    end
end

class Owner < Sequel::Model(:owners)
    set_schema do
        primary_key :id
        text :email
    end
end

class Value < Sequel::Model(:values)
    set_schema do
        set_primary_key [:app, :environment]
        text :key
        text :value
    end
end

App.create_table!
Environment.create_table!
Owner.create_table!
Value.create_table!

class Escape < Ramaze::Controller
    def index
        'Hello, World!'
    end

    def config(app, env, key)
        if request.get?
            'get me'
        elsif request.put?
            'put me'
        elsif request.post?
            'post me'
        end
    end
   
end

Ramaze.start

