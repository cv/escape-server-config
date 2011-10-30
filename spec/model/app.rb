#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__) + "/.."))
require 'init'

describe App do
  behaves_like :db_helper

  before do
      reset_db
  end

  it "should return nil value if key does not exist" do
     my_env = Environment.create(:name => 'testenv')
     my_app = App.create(:name => 'testapp')
     my_env.add_app(my_app)
     value = my_app.get_key_value(nil, my_env)
     value.nil?.should == true
  end

  it "should get default value for key" do
     my_env = Environment.create(:name => 'testenv')
     my_app = App.create(:name => 'testapp')
     my_env.add_app(my_app)
     key = Key.create(:name => 'key', :app_id=>my_app[:id])
     Value.create(:key_id => key[:id], :environment_id => Environment.default[:id], :value=>'defaultvalue')
     value = my_app.get_key_value(key, my_env)
     value[:value].should == 'defaultvalue'
     value.default?.should == true
  end

  it "should get actual value for key" do
     my_env = Environment.create(:name => 'testenv')
     my_app = App.create(:name => 'testapp')
     my_env.add_app(my_app)
     key = Key.create(:name => 'key', :app_id=>my_app[:id])
     Value.create(:key_id => key[:id], :environment_id => Environment.default[:id], :value=>'defaultvalue')
     Value.create(:key_id => key[:id], :environment_id => my_env[:id], :value=>'value')
     value = my_app.get_key_value(key, my_env)
     value[:value].should == 'value'
     value.default?.should == false
  end

  it "should add new key value" do
    my_env = Environment.create(:name => 'testenv')
    my_app = App.create(:name => 'testapp')
    my_env.add_app(my_app)
    my_app.keys.length.should == 0
    added = my_app.set_key_value('key', my_env, 'value', false)
    my_app.keys.length.should == 1
    added.should == true
    key = Key[:name => 'key', :app_id => my_app[:id]]
    Value[:key_id => key[:id], :environment_id => my_env[:id]][:value].should == 'value'
  end

  it "should add value for existing key with nil value" do
    my_env = Environment.create(:name => 'testenv')
    my_app = App.create(:name => 'testapp')
    my_env.add_app(my_app)
    key = Key.create(:name => 'key', :app_id=>my_app[:id])
    added = my_app.set_key_value('key', my_env, 'value', false)
    added.should == true
    my_app.keys.length.should == 1
    Value[:key_id => key[:id], :environment_id => my_env[:id]][:value].should == 'value'
  end

  it "should update value for existing key with non-nil value" do
    my_env = Environment.create(:name => 'testenv')
    my_app = App.create(:name => 'testapp')
    my_env.add_app(my_app)
    key = Key.create(:name => 'key', :app_id=>my_app[:id])
    value = Value.create(:key_id => key[:id], :environment_id => my_env[:id], :value=>'oldvalue')
    added = my_app.set_key_value('key', my_env, 'value', false)
    added.should == false
    my_app.keys.length.should == 1
    Value[:key_id => key[:id], :environment_id => my_env[:id]][:value].should == 'value'
  end

end
