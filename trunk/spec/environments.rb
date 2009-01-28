#!/usr/bin/env ruby

require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('../start')

describe EnvironmentsController do
    behaves_like 'http', 'xpath'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        # Make sure all tables are clean before we start
        #DB.tables.each { |table|
        #    DB[table].delete!
        #}
        App.create_table!
        Environment.create_table!
        Owner.create_table!
        Value.create_table!
        if DB[:owners].where(:name => 'nobody').empty?
            Owner.create(:name => 'nobody', :email => 'nobody@nowhere.com')
        end

        if DB[:environments].where(:name => 'default').empty?
            Environment.create(:name => 'default')
        end
    end

    it 'should get /environments' do
        got = get('/environments')
        got.status.should == 200
    end

    it 'should return 404 for an unknown environment' do
        got = get('/environments/unknown')
        got.status.should == 404
    end

    it 'should create an app on put /environments/default/appname' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default')
        got.status.should == 200
        got.body.should.include "appname"
    end

    it 'should not allow duplicate app names' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = put('/environments/default/appname')
        got.status.should == 403
    end

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

    it 'should be able to create new environment' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == ""
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

    it 'should not allow duplicate environment names' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv')
        got.status.should == 403
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

    it 'should list apps in an environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default')
        got.status.should == 200
        got.body.should.include "appname"
    end

    it 'should return 404 for non existing key' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default/appname/badkey')
        got.status.should == 404
    end

    it 'should return 404 for non existing app' do
        got = get('/environments/default/badapp')
        got.status.should == 404
    end
end
