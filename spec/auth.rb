#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'
require 'base64'
require 'digest/md5'

describe AuthController do
    behaves_like :rack_test, :db_helper

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
        authorize("me", "me")
        got = get('/auth/secret')

        got.status.should == 200
        got.body.should == "Secret Info"
    end

    it 'should not get info from /auth/secret if it supplies the wrong credentials' do
        authorize("notadmin", "notadmin")
        got = get('/auth/secret')
        got.status.should == 401
    end

    it 'should only allow environment owners to change or delete the environment' do
        got = put('/environments/mine')
        got.status.should == 201

        authorize("me", "me")
        got = post('/owner/mine')
        got.status.should == 200

        authorize("you", "you")
        got = put('/environments/mine/myapp')
        got.status.should == 401

        authorize("me", "me")
        got = put('/environments/mine/myapp')
        got.status.should == 201

        got = get('/environments/mine/myapp')
        got.status.should == 200

        authorize("you", "you")
        got = put('/environments/mine/myapp/mykey', "sheep")
        got.status.should == 401

        authorize("me", "me")
        got = put('/environments/mine/myapp/mykey', "myvalue")
        got.status.should == 201

        got = get('/environments/mine/myapp/mykey')
        got.status.should == 200
        got.body.should == "myvalue"

        authorize("you", "you")
        got = delete('/environments/mine/myapp/mykey')
        got.status.should == 401

        authorize("me", "me")
        got = delete('/environments/mine/myapp/mykey')
        got.status.should == 200

        # TODO: This is a little screwy...
#        got = get('/environments/mine/myapp/mykey')
#        got.status.should == 200
#        got.body.should.not == "myvalue"

        authorize("you", "you")
        got = delete('/environments/mine/myapp')
        got.status.should == 401

        authorize("me", "me")
        got = delete('/environments/mine/myapp')
        got.status.should == 200

        got = get('/environments/mine/myapp')
        got.status.should == 404

        authorize("you", "you")
        got = delete('/environments/mine')
        got.status.should == 401

        authorize("me", "me")
        got = delete('/environments/mine')
        got.status.should == 200

        got = get('/environments/mine')
        got.status.should == 404
    end

    it 'should be able to copy an environment owned by someone else without needing auth' do
        got = put('/environments/mine')
        got.status.should == 201

        authorize("me", "me")
        got = post('/owner/mine')
        got.status.should == 200

        header("HTTP_CONTENT_LOCATION", "mine")
        got = post('/environments/yours')
        got.status.should == 201

        got = get('/environments/yours')
        got.status.should == 200
    end

    it 'should only get the public key of an owned environment on GET /crypt/environment' do
        got = put('/environments/mine')
        got.status.should == 201

        authorize("me", "me")
        got = post('/owner/mine')
        got.status.should == 200

        header('HTTP_AUTHORIZATION', nil)
        got = get('/crypt/mine')
        got.status.should == 200
        got.content_type.should == "text/plain"
        got.body.should.not == "[]"
        got.body.should.include "-----BEGIN "
        got.body.should.include "-----END "
        got.body.should.include " PUBLIC KEY-----"
        got.body.should.not.include " PRIVATE KEY-----"

        got = get('/crypt/mine/public')
        got.status.should == 200
        got.content_type.should == "text/plain"
        got.body.should.not == "[]"
        got.body.should.include "-----BEGIN "
        got.body.should.include "-----END "
        got.body.should.include " PUBLIC KEY-----"
        got.body.should.not.include " PRIVATE KEY-----"

        got = get('/crypt/mine/private')
        got.status.should == 401

        authorize("me", "me")
        got = get('/crypt/mine')
        got.status.should == 200
        got.content_type.should == "text/plain"
        got.body.should.not == "[]"
        got.body.should.include "-----BEGIN "
        got.body.should.include "-----END "
        got.body.should.include " PUBLIC KEY-----"
        got.body.should.include " PRIVATE KEY-----"

        authorize("me", "me")
        got = get('/crypt/mine/private')
        got.status.should == 200
        got.content_type.should == "text/plain"
        got.body.should.not == "[]"
        got.body.should.include "-----BEGIN "
        got.body.should.include "-----END "
        got.body.should.not.include " PUBLIC KEY-----"
        got.body.should.include " PRIVATE KEY-----"
    end

    it 'should only update or generate new keys for an owned environment when requested by the owner' do
        got = put('/environments/mine')
        got.status.should == 201

        authorize("me", "me")
        got = post('/owner/mine')
        got.status.should == 200

        header('HTTP_AUTHORIZATION', nil)
        got = post('/crypt/mine', '')
        got.status.should == 401

        authorize("me", "me")
        got = post('/crypt/mine', '')
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

        header('HTTP_AUTHORIZATION', nil)
        got = post('/crypt/mine', :input => mykeypair)
        got.status.should == 401

        authorize("me", "me")
        got = post('/crypt/mine', mykeypair)
        got.status.should == 201

        header('HTTP_AUTHORIZATION', nil)
        got = delete('/crypt/mine')
        got.status.should == 401

        authorize("me", "me")
        got = delete('/crypt/mine')
        got.status.should == 200
    end
end
