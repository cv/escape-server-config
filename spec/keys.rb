#!/usr/bin/env ruby

require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('../start')

describe EnvironmentsController do
    behaves_like 'http', 'xpath'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        App.create_table!
        Environment.create_table!
        Owner.create_table!
        Value.create_table!
        AppsEnvironments.create_table!

        if DB[:owners].where(:name => 'nobody').empty?
            Owner.create(:name => 'nobody', :email => 'nobody@nowhere.com')
        end

        if DB[:environments].where(:name => 'default').empty?
            Environment.create(:name => 'default')
        end
    end

    # Key/Value tests
    it 'should set a key and value for default' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value
    end

    it 'should return the default value for an existing environment for which there is no explicit value' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201
        
        got = put('/environments/myenv')
        got.status.should == 201

        got = get('/environments/myenv/appname/key')
        got.status.should == 200
        got.body.should == value
    end

    it 'should allow us to update a value' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value

        newvalue = "new.value"
        got = put('/environments/default/appname/key', :input => newvalue)
        got.status.should == 200

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == newvalue
        got.body.should.not == value
    end

    it 'should not return the default value if it is set for the given environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value

        got = put('/environments/myenv')
        got.status.should == 201

        newvalue = "new.value"
        got = put('/environments/myenv/appname/key', :input => newvalue)
        got.status.should == 201

        got = get('/environments/myenv/appname/key')
        got.status.should == 200
        got.body.should == newvalue
        got.body.should.not == value
    end

    it 'should return 404 for non existing key' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default/appname/badkey')
        got.status.should == 404
    end

    it 'should return the default value when the specified app is not explicitly a member of the specified environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value

        got = put('/environments/myenv')
        got.status.should == 201

        got = get('/environments/myenv/appname/key')
        got.status.should == 200
        got.body.should == value
    end

#    it 'should list all the keys and values when just asking for the app name in the environment' do
#        got = put('/environments/default/appname')
#        got.status.should == 201
#
#        key1 = "key1"
#        value1 = "value1"
#        got = put("/environments/default/appname/#{key1}", :input => value1)
#        got.status.should == 201
#
#        key2 = "key2"
#        value2 = "value2"
#        got = put("/environments/default/appname/#{key2}", :input => value2)
#        got.status.should == 201
#
#        got = get('/environments/default/appname')
#        got.status.should == 200
#        got.body.should.not == ""
#        got.body.should.include == key1
#        got.body.should.include == key2
#        got.body.should.include == value1
#        got.body.should.include == value2
#    end
end
