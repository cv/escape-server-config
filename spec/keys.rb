#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'
require 'openssl'
require 'base64'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe EnvironmentsController, 'Key/Value bits' do
    behaves_like 'http', 'db_helper'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        reset_db
    end

    # Key/Value tests
    it 'should be able to set a key and value for default, should return it as text/plain' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value
        got.content_type.should == "text/plain"
    end

    # TODO: When we set a value, have the option to set its content type. We then get the header set when we ask for it?

    it 'should set the key in the default environment when we add it to a different environment' do
        got = put('/environments/newenv')
        got.status.should == 201

        got = put('/environments/newenv/appname')
        got.status.should == 201
    
        value = "default.value"
        got = put('/environments/newenv/appname/key', :input => value)
        got.status.should == 201
            
        got = get('/environments/default/appname/key')
        got.status.should == 200
    end

    it 'should not return values for applications that are not in specified environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = put('/environments/default/appname/key')
        got.status.should == 201
        
        got = put('/environments/myenv')
        got.status.should == 201

        got = get('/environments/myenv/appname')
        got.status.should == 404

        got = get('/environments/myenv/appname/key')
        got.status.should == 404
    end

    it 'should return the default value for an existing environment for which there is no explicit value' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201
        
        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/appname')
        got.status.should == 200

        got = get('/environments/myenv/appname/key')
        got.status.should == 200
        got.body.should == value
    end

    it 'should allow us to update a value' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value

        newvalue = "new.value"
        got = put('/environments/default/appname/key', :input => newvalue)
        got.status.should == 200

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == newvalue
        got.body.should.not == value
    end

    it 'should not return the default value if it is set for the given environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value

        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/appname')
        got.status.should == 200

        newvalue = "new.value"
        got = put('/environments/myenv/appname/key', :input => newvalue)
        got.status.should == 201

        got = get('/environments/myenv/appname/key')
        got.status.should == 200
        got.body.should == newvalue
        got.body.should.not == value
    end

    it 'should return 404 for non existing key' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default/appname/badkey')
        got.status.should == 404
    end

    it 'should return the default value when the specified app is not explicitly a member of the specified environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/appname/key', :input => value)
        got.status.should == 201

        got = get('/environments/default/appname/key')
        got.status.should == 200
        got.body.should == value

        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/appname')
        got.status.should == 200

        got = get('/environments/myenv/appname/key')
        got.status.should == 200
        got.body.should == value
    end

    it 'should list all the keys and values when just asking for the app name in the environment, default should be text/plain' do
        got = put('/environments/default/appname')
        got.status.should == 201

        key1 = "key1"
        value1 = "value1"
        got = put("/environments/default/appname/#{key1}", :input => value1)
        got.status.should == 201

        key2 = "key2"
        value2 = "value2"
        got = put("/environments/default/appname/#{key2}", :input => value2)
        got.status.should == 201

        got = get('/environments/default/appname')
        got.status.should == 200
        got.body.should.not == ""
        got.body.should.include "#{key1}=#{value1}"
        got.body.should.include "#{key2}=#{value2}"
        got.content_type.should == "text/plain"
    end

    it 'should list values for the specified environment when asking for all' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/appname')
        got.status.should == 200

        key1 = "key1"
        value1 = "value1"
        got = put("/environments/default/appname/#{key1}", :input => value1)
        got.status.should == 201

        key2 = "key2"
        value2 = "value2"
        got = put("/environments/default/appname/#{key2}", :input => value2)
        got.status.should == 201

        newvalue2 = "new.value2"
        got = put("/environments/myenv/appname/#{key2}", :input => newvalue2)
        got.status.should == 201

        got = get('/environments/myenv/appname')
        got.status.should == 200
        got.body.should.not == ""
        got.body.should.include "#{key1}=#{value1}"
        got.body.should.include "#{key2}=#{newvalue2}"
    end

    it 'should only accept \A[.a-zA-Z0-9_-]+\Z as key name' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = put('/environments/default/appname/this.is.valid_key-name')
        got.status.should == 201

        got = put('/environments/default/appname/not%20legal')
        got.status.should == 403
    end
    
    it 'should delete a not-overridden key completely from an application in the default environment' do
        got = put('/environments/default/deletetest')
        got.status.should == 201
        
        value = "default.value"
        got = put('/environments/default/deletetest/mykey', :input => value)
        got.status.should == 201

        got = delete('/environments/default/deletetest/mykey')
        got.status.should == 200
        
        got = get('/environments/default/deletetest/mykey')
        got.status.should == 404
        
    end
    
    it 'should delete a key mapping from an application in a non-default environment' do
        got = put('/environments/deletekey')
        got.status.should == 201
        
        got = put('/environments/deletekey/deletetest')
        got.status.should == 201

        value = "default.value"
        got = put('/environments/default/deletetest/mykey', :input => value)
        got.status.should == 201
        
        value = "override.value"
        got = put('/environments/deletekey/deletetest/mykey', :input => value)
        got.status.should == 201

        got = delete('/environments/deletekey/deletetest/mykey')
        got.status.should == 200
        
        got = get('/environments/deletekey/deletetest/mykey')
        got.status.should == 200
        got.body.should.not == ""
        got.body.should.include "default.value"
        got.body.should.not.include "override.value" 
               
    end
    
    it 'should not delete an overridden key from an application in the default environment' do
         got = put('/environments/deletekey')
         got.status.should == 201
    
         got = put('/environments/deletekey/deletetest')
         got.status.should == 201
    
         value = "default.value"
         got = put('/environments/default/deletetest/mykey', :input => value)
         got.status.should == 201
    
         value = "override.value"
         got = put('/environments/deletekey/deletetest/mykey', :input => value)
         got.status.should == 201
     
         got = delete('/environments/default/deletetest/mykey')
         got.status.should == 403
     
         got = get('/environments/deletekey/deletetest/mykey')
         got.status.should == 200
         got.body.should.not == ""
         got.body.should.include "override.value"
         got.body.should.not.include "default.value"
    end
    
    it 'should encrypt a key value when asked and it should be decryptable by the private key' do
        got = put('/environments/encryptvalue')
        got.status.should == 201

        got = put('/environments/encryptvalue/anapp')
        got.status.should == 201

        got = get('/crypt/encryptvalue/private')
        got.status.should == 200
        priv_key = OpenSSL::PKey::RSA.new(got.body)

        value = "my.value"
        got = put('/environments/encryptvalue/anapp/mykey', :input => value)
        got.status.should == 201
        
        got = get('/environments/encryptvalue/anapp/mykey')
        got.status.should == 200 
        got.body.should == value
        
        got = put('/environments/encryptvalue/anapp/mykey', :input => value, :encrypt => "true")
        got.status.should == 200
        
        got = get('/environments/encryptvalue/anapp/mykey')
        got.status.should == 200 
        got.body.should.not == value

        un64body = Base64.decode64(got.body)
        decrypt = priv_key.private_decrypt(un64body)
        decrypt.should == value
    end

    it 'should play nice when trying to delete a key from an env that has not explicit value set' do
        got = put('/environments/deleteenv')
        got.status.should == 201
   
        got = put('/environments/deleteenv/deletetest')
        got.status.should == 201
   
        value = "default.value"
        got = put('/environments/default/deletetest/mykey', :input => value)
        got.status.should == 201
   
        got = delete('/environments/deleteenv/deletetest/mykey')
        got.status.should == 404
    
        got = get('/environments/deleteenv/deletetest/mykey')
        got.status.should == 200
        got.body.should.include "default.value"
    end
end
