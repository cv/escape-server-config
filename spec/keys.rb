#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe EnvironmentsController, 'Key/Value bits' do
    behaves_like 'http', 'db_helper'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        reset_db
    end

    # Key/Value tests
    it 'should set a key and value for default, default return should be text/plain but we can ask for application/json' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value
        got.content_type.should == "text/plain"

        # TODO: Put this in
        #got = get('/environments/default/appname/key', :headers => {"Accept" => "application/json"})
        #got.status.should == 200
        #got.body.should == value
        #got.content_type.should == "application/json"

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

    it 'should list all the keys and values when just asking for the app name in the environment, default should be text/plain but should do application/json if asked' do
        got = put('/environments/default/appname')
        got.status.should == 201

        key1 = "key1"
        value1 = "value1"
        got = put("/environments/default/appname/#{key1}", :input => value1)
        got.status.should == 201

        key2 = "key2"
        value2 = "value2"
        got = put("/environments/default/appname/#{key2}", :input => value2)
        got.status.should == 201

        got = get('/environments/default/appname')
        got.status.should == 200
        got.body.should.not == ""
        got.body.should.include "#{key1}=#{value1}"
        got.body.should.include "#{key2}=#{value2}"
        got.content_type.should == "text/plain"
        
        # TODO: Put this in
        #got = get('/environments/default/appname')
        #got.status.should == 200
        #got.body.should.not == ""
        #got.body.should.include "#{key1}=#{value1}"
        #got.body.should.include "#{key2}=#{value2}"
        #got.content_type.should == "application/json"
    end

    it 'should list values for the specified environment when asking for all' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/appname')
        got.status.should == 200

        key1 = "key1"
        value1 = "value1"
        got = put("/environments/default/appname/#{key1}", :input => value1)
        got.status.should == 201

        key2 = "key2"
        value2 = "value2"
        got = put("/environments/default/appname/#{key2}", :input => value2)
        got.status.should == 201

        newvalue2 = "new.value2"
        got = put("/environments/myenv/appname/#{key2}", :input => newvalue2)
        got.status.should == 201

        got = get('/environments/myenv/appname')
        got.status.should == 200
        got.body.should.not == ""
        got.body.should.include "#{key1}=#{value1}"
        got.body.should.include "#{key2}=#{newvalue2}"
    end

end
