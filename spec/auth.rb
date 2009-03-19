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
        Owner.create(:name => "admin", :email => "email", :password => MD5.hexdigest("admin"))
        #got = get('/auth/secret', :auth => Base64.encode64("admin:admin"))
        # TODO: Send a patch to Ramaze to make the above work instead of ugly below...
        got = raw_mock_request(:get, '/auth/secret', 'HTTP_AUTHORIZATION' => Base64.encode64("admin:admin"))
        got.status.should == 200
        got.body.should == "Secret Info"
    end

    it 'should not get info from /auth/secret if it supplies the wrong credentials' do
        got = raw_mock_request(:get, '/auth/secret', 'HTTP_AUTHORIZATION' => Base64.encode64("notadmin:notadmin"))
        got.status.should == 401
    end


    # Key/Value tests
#    it 'should be able to set a key and value for default, should return it as text/plain' do
#        got = put('/environments/default/appname')
#        got.status.should == 201
#
#        value = "default.value"
#        got = put('/environments/default/appname/key', :input => value)
#        got.status.should == 201
#
#        got = get('/environments/default/appname/key')
#        got.status.should == 200
#        got.body.should == value
#        got.content_type.should == "text/plain"
#    end

    # TODO: When we set a value, have the option to set its content type. We then get the header set when we ask for it?

#    it 'should set the key in the default environment when we add it to a different environment' do
#        got = put('/environments/newenv')
#        got.status.should == 201
#
#        got = put('/environments/newenv/appname')
#        got.status.should == 201
#    
#        value = "default.value"
#        got = put('/environments/newenv/appname/key', :input => value)
#        got.status.should == 201
#            
#        got = get('/environments/default/appname/key')
#        got.status.should == 200
#    end

end
