#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

require 'time'

class Value < Sequel::Model(:values)
  plugin :schema
  plugin :hook_class_methods

  many_to_one :key, :class => :Key
  many_to_one :environment, :class => :Environment

  set_schema do
    primary_key :id, :null => false
    String :value
    Boolean :is_encrypted
    DateTime :modified

    foreign_key :key_id, :table => :keys, :type => Integer
    foreign_key :environment_id, :table => :environments, :type => Integer
  end

  def before_save
    return false if super == false
    self.modified = Time.now
  end

  def default?
    self[:environment_id] == Environment.default[:id]
  end
end

EscData.init_model(Value)
