#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('../helper/db_helper')

describe App do
  behaves_like 'db_helper'
  
  before do
      reset_db
  end
  
  it "should return nil value if key does not exist" do
     myEnv = Environment.create(:name => 'testenv')
     myApp = App.create(:name => 'testapp')
     myEnv.add_app(myApp)
     value = myApp.get_key_value(nil, myEnv)
     value.nil?.should == true
  end
  
  it "should get default value for key" do
     myEnv = Environment.create(:name => 'testenv')
     myApp = App.create(:name => 'testapp')
     myEnv.add_app(myApp)
     key = Key.create(:name => 'key', :app_id=>myApp[:id])
     Value.create(:key_id => key[:id], :environment_id => Environment.default[:id], :value=>'defaultvalue')
     value = myApp.get_key_value(key, myEnv)
     value[:value].should == 'defaultvalue'
     value.default?.should == true
  end
  
  it "should get actual value for key" do
     myEnv = Environment.create(:name => 'testenv')
     myApp = App.create(:name => 'testapp')
     myEnv.add_app(myApp)
     key = Key.create(:name => 'key', :app_id=>myApp[:id])
     Value.create(:key_id => key[:id], :environment_id => Environment.default[:id], :value=>'defaultvalue')
     Value.create(:key_id => key[:id], :environment_id => myEnv[:id], :value=>'value')
     value = myApp.get_key_value(key, myEnv)
     value[:value].should == 'value'
     value.default?.should == false
  end
  
  it "should add new key value" do
    myEnv = Environment.create(:name => 'testenv')
    myApp = App.create(:name => 'testapp')
    myEnv.add_app(myApp)
    myApp.keys.length.should == 0
    added = myApp.set_key_value('key', myEnv, 'value', false)
    myApp.keys.length.should == 1
    added.should == true
    key = Key[:name => 'key', :app_id => myApp[:id]]
    Value[:key_id => key[:id], :environment_id => myEnv[:id]][:value].should == 'value'
  end
  
  it "should add value for existing key with nil value" do
    myEnv = Environment.create(:name => 'testenv')
    myApp = App.create(:name => 'testapp')
    myEnv.add_app(myApp)
    key = Key.create(:name => 'key', :app_id=>myApp[:id])
    added = myApp.set_key_value('key', myEnv, 'value', false)
    added.should == true
    myApp.keys.length.should == 1
    Value[:key_id => key[:id], :environment_id => myEnv[:id]][:value].should == 'value'
  end
  
  it "should update value for existing key with non-nil value" do
    myEnv = Environment.create(:name => 'testenv')
    myApp = App.create(:name => 'testapp')
    myEnv.add_app(myApp)
    key = Key.create(:name => 'key', :app_id=>myApp[:id])
    value = Value.create(:key_id => key[:id], :environment_id => myEnv[:id], :value=>'oldvalue')
    added = myApp.set_key_value('key', myEnv, 'value', false)
    added.should == false
    myApp.keys.length.should == 1
    Value[:key_id => key[:id], :environment_id => myEnv[:id]][:value].should == 'value'
  end
  
end