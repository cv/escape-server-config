#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'
require 'base64'
require 'md5'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe OwnerController do
    behaves_like 'http', 'db_helper'

    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

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

        got = raw_mock_request(:post, '/owner/myenv', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        got = get('/owner/myenv')
        got.status.should == 200
        got.body.should == "me"
        got.content_type.should == "text/plain"

        got = delete('/owner/myenv')
        got.status.should == 401

        got = raw_mock_request(:delete, '/owner/myenv', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
        got.status.should == 200

        got = get('/owner/myenv')
        got.status.should == 200
        got.body.should == "nobody"
        got.content_type.should == "text/plain"
    end

    it 'should not be able to change the owner of the default environment' do
        me = Owner.create(:name => "me", :email => "me", :password => MD5.hexdigest("me"))

        got = raw_mock_request(:post, '/owner/default', 'HTTP_AUTHORIZATION' => Base64.encode64("me:me"))
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
