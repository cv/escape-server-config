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

        got = put('/environments/mine/myapp/mykey', :input => "sheep")
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

        # TODO: This is a little screwy...
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

    it 'should only get the public key of an owned environment on GET /crypt/environment' do
        got = put('/environments/mine')
        got.status.should == 201
        
        got = raw_mock_request(:post, '/owner/mine', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        got = get('/crypt/mine')
        got.status.should == 200
        got.content_type.should == "text/plain"
        got.body.should.not == "[]"
        got.body.should.include "-----BEGIN RSA PUBLIC KEY-----" 
        got.body.should.include "-----END RSA PUBLIC KEY-----" 
        got.body.should.not.include "-----BEGIN RSA PRIVATE KEY-----" 
        got.body.should.not.include "-----END RSA PRIVATE KEY-----" 

        got = get('/crypt/mine/public')
        got.status.should == 200
        got.content_type.should == "text/plain"
        got.body.should.not == "[]"
        got.body.should.include "-----BEGIN RSA PUBLIC KEY-----" 
        got.body.should.include "-----END RSA PUBLIC KEY-----" 
        got.body.should.not.include "-----BEGIN RSA PRIVATE KEY-----" 
        got.body.should.not.include "-----END RSA PRIVATE KEY-----" 

        got = get('/crypt/mine/private')
        got.status.should == 401

        got = raw_mock_request(:get, '/crypt/mine', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200
        got.content_type.should == "text/plain"
        got.body.should.not == "[]"
        got.body.should.include "-----BEGIN RSA PUBLIC KEY-----" 
        got.body.should.include "-----END RSA PUBLIC KEY-----" 
        got.body.should.include "-----BEGIN RSA PRIVATE KEY-----" 
        got.body.should.include "-----END RSA PRIVATE KEY-----" 

        got = raw_mock_request(:get, '/crypt/mine/private', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200
        got.content_type.should == "text/plain"
        got.body.should.not == "[]"
        got.body.should.not.include "-----BEGIN RSA PUBLIC KEY-----" 
        got.body.should.not.include "-----END RSA PUBLIC KEY-----" 
        got.body.should.include "-----BEGIN RSA PRIVATE KEY-----" 
        got.body.should.include "-----END RSA PRIVATE KEY-----" 
    end

    it 'should only update or generate new keys for an owned environment when requested by the owner' do
        got = put('/environments/mine')
        got.status.should == 201
        
        got = raw_mock_request(:post, '/owner/mine', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        got = post('/crypt/mine', '')
        got.status.should == 401

        got = raw_mock_request(:post, '/crypt/mine', {'HTTP_AUTHORIZATION' => Base64.encode64("me:me"), :input => ''})
        got.status.should == 201

        mykeypair = "
-----BEGIN RSA PUBLIC KEY-----
MEgCQQCsEJqRpZbUL8jDKuz8O651LDSI50/7nE5EzI+1IussWGpDgrm5mNtEJay
KEZqWGC3Xv+7YOiW+naT3Uuwpv8uzAgMBAAE=
-----END RSA PUBLIC KEY-----

-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAKwQmpGlltQvyMMq7Pw7rnUsNIjnT/ucTkTMj7Ui6yxYakOCubmY
20QlrIoRmpYYLde/7tg6Jb6dpPdS7Cm/y7MCAwEAAQJAT2F9nfISCqRc78Vu/dMe
4knZlst4d/Edntns9rk8XAFQpXo8NyX1WIQvzfZFF4vuzw7eBSkADkV+2+EH5kuU
6QIhANJlI/W8w0CpwO0r0rYm7PUvB2EirNluzSu1peANJme1AiEA0VyDPnoCWQ5T
6ZMuR5N1TfzPPGrOFffc5MaiY6QRNscCICO6Sx36vQlpCjr8Ox71gz2ri8xB8CpI
N40Znp5qfUAVAiEAhWhfFVOn5Vm07NTlm6SCDkT3RTeFxQfhkUJlvfqRIYcCIHjk
kFDyd3XHD/9WeQfPCMX7iODSLXzvU6HuVzsn5T6X
-----END RSA PRIVATE KEY-----"

        got = post('/crypt/mine', :input => mykeypair)
        got.status.should == 401

        got = raw_mock_request(:post, '/crypt/mine', {'HTTP_AUTHORIZATION' => Base64.encode64("me:me"), :input => mykeypair})
        got.status.should == 201

        got = delete('/crypt/mine')
        got.status.should == 401

        got = raw_mock_request(:delete, '/crypt/mine', {'HTTP_AUTHORIZATION' => Base64.encode64("me:me")})
        got.status.should == 200
    end
end
