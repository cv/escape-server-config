#!/usr/bin/env ruby

require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe EnvironmentsController, 'Environment bits' do
    behaves_like 'http', 'db_helper'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        reset_db
    end

    # Environment tests
    it 'should get /environments and list them' do
        got = get('/environments')
        got.status.should == 200
        got.body.should == '["default"]'
    end

    it 'should return 404 for an unknown environment' do
        got = get('/environments/unknown')
        got.status.should == 404
    end

    it 'should be able to create new environment using PUT' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == "[]"
    end

    it 'should be able to create new environment using POST' do
        got = post('/environments/myenv')
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
