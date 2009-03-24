#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'
require 'base64'
require 'md5'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe AuthController do
    behaves_like 'http', 'db_helper'

    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    def encode_credentials(username, password)
        "Basic " + Base64.encode64("#{username}:#{password}")
    end
    
    before do
        reset_db
        @me = Owner.create(:name => "me", :email => "me", :password => MD5.hexdigest("me"))
    end

    it 'should not need auth for /auth' do
        got = get('/auth') 
        got.status.should == 200
        got.body.should == "Public Info"
    end

    it 'should need auth for /auth/secret' do
        got = get('/auth/secret')
        got.status.should == 401
    end

    it 'should get info from /auth/secret if it supplies the right credentials' do
        #got = get('/auth/secret', :auth => Base64.encode64("me:me"))
        # TODO: Send a patch to Ramaze to make the above work instead of ugly below...
        got = raw_mock_request(:get, '/auth/secret', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200
        got.body.should == "Secret Info"
    end

    it 'should not get info from /auth/secret if it supplies the wrong credentials' do
        got = raw_mock_request(:get, '/auth/secret', 'HTTP_AUTHORIZATION' => Base64.encode64("notadmin:notadmin"))
        got.status.should == 401
    end

    it 'should only allow environment owners to change or delete the environment' do
        got = put('/environments/mine')
        got.status.should == 201

        got = raw_mock_request(:post, '/owner/mine', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        got = put('/environments/mine/myapp')
        got.status.should == 401

        got = raw_mock_request(:put, '/environments/mine/myapp', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 201

        got = get('/environments/mine/myapp')
        got.status.should == 200

        got = put('/environments/mine/myapp/mykey')
        got.status.should == 401

        got = raw_mock_request(:put, '/environments/mine/myapp/mykey', {'HTTP_AUTHORIZATION' => Base64.encode64("me:me"), :input => "myvalue"})
        got.status.should == 201

        got = get('/environments/mine/myapp/mykey')
        got.status.should == 200
        got.body.should == "myvalue"

        got = delete('/environments/mine/myapp/mykey')
        got.status.should == 401

        got = raw_mock_request(:delete, '/environments/mine/myapp/mykey', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        # This is a little screwy...
#        got = get('/environments/mine/myapp/mykey')
#        got.status.should == 200
#        got.body.should.not == "myvalue"

        got = delete('/environments/mine/myapp')
        got.status.should == 401

        got = raw_mock_request(:delete, '/environments/mine/myapp', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        got = get('/environments/mine/myapp')
        got.status.should == 404

        got = delete('/environments/mine')
        got.status.should == 401

        got = raw_mock_request(:delete, '/environments/mine', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        got = get('/environments/mine')
        got.status.should == 404
    end

    it 'should be able to copy an environment owned by someone else without needing auth' do
        got = put('/environments/mine')
        got.status.should == 201

        got = raw_mock_request(:post, '/owner/mine', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        got = raw_mock_request(:post, '/environments/mine', 'HTTP_CONTENT_LOCATION' => "yours")
        got.status.should == 201
        
        got = get('/environments/yours')
        got.status.should == 200 
    end
end
