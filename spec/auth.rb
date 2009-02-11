#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe EnvironmentsController, 'Authentication' do
    behaves_like 'http', 'db_helper'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        reset_db
    end

    # Authentication tests
    it 'should set the default owner to nobody' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = post('/environments/myenv/appname')
        got.status.should == 201

        got = get('/environments/myenv/appname')
        got.status.should == 200
        got.headers['X-Owner'].should == "nobody"
    end

    # POST /environment/myenv/myapp?owner=me
    it 'should be able to specify who the owner of an app is in a certain environment' do
        got = put('/environments/myenv')
        got.status.should == 201

        Owner.create(:name => "me", :email => "me@mydomain.com", :password => "password")

        got = post('/environments/myenv/appname', :owner => 'me')
        got.status.should == 201

        got = get('/environments/myenv/appname')
        got.status.should == 200
        got.headers['X-Owner'].should == "me"
    end

    it 'should return a 404 if the specified owner does not exist' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = post('/environments/myenv/appname', :owner => 'me')
        got.status.should == 404
    end

    it 'should be able to change the owner of an environment if nobody owns it' do
        got = put('/environments/myenv')
        got.status.should == 201

        Owner.create(:name => "me", :email => "me@mydomain.com", :password => "password")

        got = post('/environments/myenv/appname')
        got.status.should == 201

        got = get('/environments/myenv/appname')
        got.status.should == 200
        got.headers['X-Owner'].should == "nobody"

        got = post('/environments/myenv/appname', :owner => 'me')
        got.status.should == 200

        got = get('/environments/myenv/appname')
        got.status.should == 200
        got.headers['X-Owner'].should == "me"
    end

    it 'should not be able to change the owner of the default environment ever' do
        Owner.create(:name => "me", :email => "me@mydomain.com", :password => "password")

        got = post('/environments/default/appname', :owner => 'me')
        got.status.should == 201

        got = get('/environments/default/appname')
        got.status.should == 200
        got.headers['X-Owner'].should == "nobody"
    end

    it 'should be able to change the ower of an environment as the owner if not nobody' do
        got = put('/environments/myenv')
        got.status.should == 201

        Owner.create(:name => "me", :email => "me@mydomain.com", :password => "mypassword")
        Owner.create(:name => "you", :email => "you@yourdomain.com", :password => "yourpassword")

        got = post('/environments/myenv/appname', :owner => 'me')
        got.status.should == 201

        got = post('/environments/myenv/appname', :owner => 'you')
        # TODO: Fix it...
        #got.status.should == 401

        #got = post('/environments/myenv/appname', :owner => 'you', :user => 'me')
        #got.status.should == 200
    end

#    it 'should be able to restrict changes to values for an app in a certain environment' do
#    end
end
