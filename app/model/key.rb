#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

class Key < Sequel::Model(:keys)
  plugin :schema

  many_to_one :app, :class => :App
  one_to_many :values, :class => :Value

  set_schema do
    primary_key :id, :null => false
    String :name

    foreign_key :app_id, :table => :apps, :type => Integer
  end
end

EscData.init_model(Key)

