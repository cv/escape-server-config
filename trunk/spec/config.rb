#!/usr/bin/env ruby

require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('../start')

describe ConfigController do
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
            Owner.new(:name => 'nobody', :email => 'nobody@nowhere.com').save
        end
    end

    it 'should get /config' do
        got = get('/config')
        got.status.should == 200
    end

    it 'should return 404 for an unknown app' do
        got = get('/config/unknown')
        got.status.should == 404
    end

    it 'should create an app on put /config/appname' do
        got = put('/config/appname')
        got.status.should == 201

        got = get('/config/appname')
        got.status.should == 200
    end

    it 'should not allow duplicate app names' do
        got = put('/config/appname')
        got.status.should == 201

        got = put('/config/appname')
        got.status.should == 403
    end

    it 'should put /config' do
        got = put('/config')
        got.status.should == 400
    end

    it 'should post /config' do
        got = post('/config')
        got.status.should == 200
    end
end
