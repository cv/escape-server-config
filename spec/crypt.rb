#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe CryptController, 'Encryption bits' do
    behaves_like 'http', 'db_helper'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        reset_db
    end
    
    # Encryption tests
    
       it 'should not accept put on /crypt' do
           got = put('/crypt')
           got.status.should == 400
       end

       it 'should do nothing on GET /crypt' do
           got = get('/crypt')
           got.status.should == 400
       end
       
       it 'should do nothing on DELETE of a missing env' do
           got = delete('/crypt/flibble')
           got.status.should == 404
       end

       it 'should return 404 when trying to GET an unknown environment' do
           got = get('/crypt/missing')
           got.status.should == 404
       end
       
       it 'should get keys when trying to GET an existing environment' do
           got = put('/environments/anenv')
           got.status.should == 201
           
           got = get('/crypt/anenv')
           got.status.should == 200
           got.content_type.should == "text/plain"
           got.body.should.not == "[]"
           got.body.should.include "-----BEGIN RSA PUBLIC KEY-----" 
           got.body.should.include "-----END RSA PUBLIC KEY-----" 
           got.body.should.include "-----BEGIN RSA PRIVATE KEY-----" 
           got.body.should.include "-----END RSA PRIVATE KEY-----" 
       end
       
       it 'should get just a public key when trying to GET a public key' do
           got = put('/environments/anenv')
           got.status.should == 201
           
           got = get('/crypt/anenv/public')
           got.status.should == 200
           got.content_type.should == "text/plain"
           got.body.should.not == "[]"
           got.body.should.include "-----BEGIN RSA PUBLIC KEY-----" 
           got.body.should.include "-----END RSA PUBLIC KEY-----" 
           got.body.should.not.include "-----BEGIN RSA PRIVATE KEY-----" 
           got.body.should.not.include "-----END RSA PRIVATE KEY-----" 
       end  
       
       it 'should get just a private key when trying to GET a private key' do
           got = put('/environments/anenv')
           got.status.should == 201
           
           got = get('/crypt/anenv/private')
           got.status.should == 200
           got.content_type.should == "text/plain"
           got.body.should.not == "[]"
           got.body.should.not.include "-----BEGIN RSA PUBLIC KEY-----" 
           got.body.should.not.include "-----END RSA PUBLIC KEY-----" 
           got.body.should.include "-----BEGIN RSA PRIVATE KEY-----" 
           got.body.should.include "-----END RSA PRIVATE KEY-----" 
       end     

       it 'should delete an existing keypair' do
           got = put('/environments/delete_me')
           got.status.should == 201
       
           got = delete('/crypt/delete_me')
           got.status.should == 200
       
           got = get('/crypt/delete_me')
           got.status.should == 200
           got.body.should.not.include "-----BEGIN RSA PUBLIC KEY-----" 
           got.body.should.not.include "-----BEGIN RSA PRIVATE KEY-----" 
       end
       
       it 'should not delete default keya' do    
           got = delete('/crypt/default')
           got.status.should == 401
       end
        
       it 'should not encrypt the default environment' do
           got = put('/crypt/default')
           got.status.should == 401
           
           got = get('/crypt/default')
           got.status.should == 200
           got.body.should.not.include "-----BEGIN RSA PUBLIC KEY-----" 
           got.body.should.not.include "-----BEGIN RSA PRIVATE KEY-----"
       end
    
end