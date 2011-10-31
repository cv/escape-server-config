#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

class AppsEnvironments < Sequel::Model
  plugin :schema

  set_schema do
    Integer :app_id
    Integer :environment_id
  end
end

EscData.init_model(AppsEnvironments)

