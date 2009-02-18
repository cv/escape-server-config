#!/usr/bin/env ruby

require 'rubygems'
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
    it 'should not accept put on /environments' do
        got = put('/environments/')
        got.status.should == 400
    end

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

    it 'should only accept \A[.a-zA-Z0-9_-]+\Z as environment name' do
        got = put('/environments/Legal-env_name0')
        got.status.should == 201

        got = put('/environments/still.legal')
        got.status.should == 201

        got = put('/environments/not%20legal')
        got.status.should == 403
    end
    
    it 'should delete an existing environment' do
        got = put('/environments/delete_me')
        got.status.should == 201
      
        got = delete('/environments/delete_me')
        got.status.should == 200
        
        got = get('/environments/delete_me')
        got.status.should == 404
    end
    
    it 'should not delete a missing environment' do
        got = delete('/environments/i_dont_exist')
        got.status.should == 404
    end
    
    it 'should not delete the default environment' do
        got = delete('/environments/default')
        got.status.should == 403
    end
    
    it 'should delete an existing application from an environment' do
        got = put('/environments/myenv')
        got.status.should == 201
      
        got = put('/environments/myenv/myapp')
        got.status.should == 201
      
        got = delete('/environments/myenv/myapp')
        got.status.should == 200
        
        got = get('/environments/myenv/myapp')
        got.status.should == 404
        
    end
    
end
