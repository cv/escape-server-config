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

    # Environment tests
    it 'should get /environments' do
        got = get('/environments')
        got.status.should == 200
    end

    it 'should return 404 for an unknown environment' do
        got = get('/environments/unknown')
        got.status.should == 404
    end

    it 'should be able to create new environment' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == "[]"
    end

    it 'should not allow duplicate environment names' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv')
        got.status.should == 403
    end
end
