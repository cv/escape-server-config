#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__) + "/.."))
require 'init'

describe Value do
  behaves_like 'db_helper'
  
  before do
      reset_db
  end
  
  it "should return true if default" do
    myApp = App.create(:name => 'testapp')
    Environment.default.add_app(myApp)
    aKey = Key.create(:name => 'key', :app_id => myApp[:id])
    value = Value.create(:key_id => aKey[:id], :environment_id => Environment.default[:id], :value => value, :is_encrypted => false)
    value.default?.should == true 
  end
  
  it "should return false if not default" do
    anEnv = Environment.create(:name => 'test')
    myApp = App.create(:name => 'testapp')
    anEnv.add_app(myApp)
    aKey = Key.create(:name => 'key', :app_id => myApp[:id])
    value = Value.create(:key_id => aKey[:id], :environment_id => anEnv[:id], :value => value, :is_encrypted => false)
    value.default?.should == false 
  end
  
end
