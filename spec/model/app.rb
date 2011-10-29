#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__) + "/.."))
require 'init'

describe App do
  behaves_like :db_helper

  before do
      reset_db
  end

  it "should return nil value if key does not exist" do
     my_env = Environment.create(:name => 'testenv')
     myApp = App.create(:name => 'testapp')
     my_env.add_app(myApp)
     value = myApp.get_key_value(nil, my_env)
     value.nil?.should == true
  end

  it "should get default value for key" do
     my_env = Environment.create(:name => 'testenv')
     myApp = App.create(:name => 'testapp')
     my_env.add_app(myApp)
     key = Key.create(:name => 'key', :app_id=>myApp[:id])
     Value.create(:key_id => key[:id], :environment_id => Environment.default[:id], :value=>'defaultvalue')
     value = myApp.get_key_value(key, my_env)
     value[:value].should == 'defaultvalue'
     value.default?.should == true
  end

  it "should get actual value for key" do
     my_env = Environment.create(:name => 'testenv')
     myApp = App.create(:name => 'testapp')
     my_env.add_app(myApp)
     key = Key.create(:name => 'key', :app_id=>myApp[:id])
     Value.create(:key_id => key[:id], :environment_id => Environment.default[:id], :value=>'defaultvalue')
     Value.create(:key_id => key[:id], :environment_id => my_env[:id], :value=>'value')
     value = myApp.get_key_value(key, my_env)
     value[:value].should == 'value'
     value.default?.should == false
  end

  it "should add new key value" do
    my_env = Environment.create(:name => 'testenv')
    myApp = App.create(:name => 'testapp')
    my_env.add_app(myApp)
    myApp.keys.length.should == 0
    added = myApp.set_key_value('key', my_env, 'value', false)
    myApp.keys.length.should == 1
    added.should == true
    key = Key[:name => 'key', :app_id => myApp[:id]]
    Value[:key_id => key[:id], :environment_id => my_env[:id]][:value].should == 'value'
  end

  it "should add value for existing key with nil value" do
    my_env = Environment.create(:name => 'testenv')
    myApp = App.create(:name => 'testapp')
    my_env.add_app(myApp)
    key = Key.create(:name => 'key', :app_id=>myApp[:id])
    added = myApp.set_key_value('key', my_env, 'value', false)
    added.should == true
    myApp.keys.length.should == 1
    Value[:key_id => key[:id], :environment_id => my_env[:id]][:value].should == 'value'
  end

  it "should update value for existing key with non-nil value" do
    my_env = Environment.create(:name => 'testenv')
    myApp = App.create(:name => 'testapp')
    my_env.add_app(myApp)
    key = Key.create(:name => 'key', :app_id=>myApp[:id])
    value = Value.create(:key_id => key[:id], :environment_id => my_env[:id], :value=>'oldvalue')
    added = myApp.set_key_value('key', my_env, 'value', false)
    added.should == false
    myApp.keys.length.should == 1
    Value[:key_id => key[:id], :environment_id => my_env[:id]][:value].should == 'value'
  end

end
