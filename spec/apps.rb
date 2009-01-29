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
        if DB[:owners].where(:name => 'nobody').empty?
            Owner.create(:name => 'nobody', :email => 'nobody@nowhere.com')
        end

        if DB[:environments].where(:name => 'default').empty?
            Environment.create(:name => 'default')
        end
    end

    # App tests
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

    it 'should list apps in an environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default')
        got.status.should == 200
        got.body.should.include "appname"
    end

    it 'should return 404 for non existing app' do
        got = get('/environments/default/badapp')
        got.status.should == 404
    end
end
