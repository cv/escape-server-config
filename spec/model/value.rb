#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__) + "/.."))
require 'init'

describe Value do
  behaves_like :db_helper

  before do
      reset_db
  end

  it "should return true if default" do
    my_app = App.create(:name => 'testapp')
    Environment.default.add_app(my_app)
    key = Key.create(:name => 'key', :app_id => my_app[:id])
    value = Value.create(:key_id => key[:id], :environment_id => Environment.default[:id], :value => value, :is_encrypted => false)
    value.default?.should == true
  end

  it "should return false if not default" do
    env = Environment.create(:name => 'test')
    my_app = App.create(:name => 'testapp')
    env.add_app(my_app)
    key = Key.create(:name => 'key', :app_id => my_app[:id])
    value = Value.create(:key_id => key[:id], :environment_id => env[:id], :value => value, :is_encrypted => false)
    value.default?.should == false
  end

end
