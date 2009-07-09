#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'
require 'base64'
require 'md5'

describe OwnerController do
    behaves_like :rack_test, :db_helper

    before do
        reset_db
    end

    def encode_credentials(username, password)
        "Basic " + Base64.encode64("#{username}:#{password}")
    end

    it 'should return a 400 on GET /owner' do
        got = get('/owner')
        got.status.should == 400
    end

    it 'should get the owner of an environment on GET /owner/environment' do
        got = get('/owner/default')
        got.status.should == 200
        got.body.should == "nobody"
        got.content_type.should == "text/plain"
    end

    it 'should get a 404 for an environment that does not exist' do
        got = get('/owner/nothere')
        got.status.should == 404

        got = post('/owner/nothere')
        got.status.should == 404
    end

    it 'should set the owner of an environment to specified user on POST /owner/environment, and give it up on delete' do
        me = Owner.create(:name => "me", :email => "me", :password => MD5.hexdigest("me"))
        env = Environment.create(:name => "myenv")

        got = post('/owner/myenv')
        got.status.should == 401

        authorize("me", "me")
        got = post('/owner/myenv')
        got.status.should == 200

        got = get('/owner/myenv')
        got.status.should == 200
        got.body.should == "me"
        got.content_type.should == "text/plain"

        authorize("you", "you")
        got = delete('/owner/myenv')
        got.status.should == 401

        authorize("me", "me")
        got = delete('/owner/myenv')
        got.status.should == 200

        got = get('/owner/myenv')
        got.status.should == 200
        got.body.should == "nobody"
        got.content_type.should == "text/plain"
    end

    it 'should not be able to change the owner of the default environment' do
        me = Owner.create(:name => "me", :email => "me", :password => MD5.hexdigest("me"))

        authorize("me", "me")
        got = post('/owner/default')
        got.status.should == 403
    end

    it 'should make new environments be owned by nobody' do
        env = Environment.create(:name => "myenv")

        got = get('/owner/myenv')
        got.status.should == 200
        got.body.should == "nobody"
        got.content_type.should == "text/plain"
    end
end
