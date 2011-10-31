#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

class Owner < Sequel::Model(:owners)
  plugin :validation_class_methods
  plugin :schema

  one_to_many :environments, :class => :Environment

  set_schema do
    primary_key :id, :null => false
    String :name
    String :email, :null => false
    String :password, :null => false
  end

  validates_uniqueness_of :name
  validates_uniqueness_of :email
end

EscData.init_model(Owner)

if Owner[:name => 'nobody'].nil?
  nobody = Owner.create(:name => 'nobody', :email => 'nobody@nowhere.com', :password => 'nothing')
end

