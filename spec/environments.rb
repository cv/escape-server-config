#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'
require 'ramaze'
require 'ramaze/spec/helper'
require 'base64'
require 'md5'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe EnvironmentsController, 'Environment bits' do
    behaves_like 'http', 'db_helper'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        reset_db
    end

    def encode_credentials(username, password)
        "Basic " + Base64.encode64("#{username}:#{password}")
    end

    # Environment tests
    it 'should not accept put on /environments' do
        got = put('/environments/')
        got.status.should == 400
    end

    it 'should list environment names on GET /environments' do
        got = get('/environments')
        got.status.should == 200
        got.body.should == '["default"]'
        got.content_type.should == "application/json"
    end

    it 'should return 404 when trying to GET an unknown environment' do
        got = get('/environments/unknown')
        got.status.should == 404
    end

    it 'should be able to create new environment using PUT' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == "[]"
        got.content_type.should == "application/json"
    end

    it 'should not be able to create new environment using POST' do
        got = post('/environments/myenv')
        got.status.should == 406
    
        got = get('/environments/myenv')
        got.status.should == 404
    end

    it 'should not alter an existing environment if we PUT to it' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/myapp')
        got.status.should == 201

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == '["myapp"]'
        
        got = put('/environments/myenv')
        got.status.should == 200

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == '["myapp"]'
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

    it 'should copy an environment' do
        got = put('/environments/copyme')
        got.status.should == 201
         
        got = raw_mock_request(:post, '/environments/mycopy', 'HTTP_CONTENT_LOCATION' => "copyme")
        got.status.should == 201
        
        got = get('/environments/mycopy')
        got.status.should == 200 
    end

    it 'should throw a 409 error if trying to copy to an environment that already exists' do
        got = put('/environments/copyme')
        got.status.should == 201
         
        got = put('/environments/mycopy')
        got.status.should == 201
         
        got = raw_mock_request(:post, '/environments/mycopy', 'HTTP_CONTENT_LOCATION' => "copyme")
        got.status.should == 409
    end
end
