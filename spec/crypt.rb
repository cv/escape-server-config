#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'

require 'openssl'

describe CryptController, 'Encryption bits' do
    behaves_like :rack_test, :db_helper

    before do
        reset_db
    end

    def encode_credentials(username, password)
        "Basic " + Base64.encode64("#{username}:#{password}")
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
           got.body.should.include "-----BEGIN "
           got.body.should.include "-----END "
           got.body.should.include " PUBLIC KEY-----"
           got.body.should.include " PRIVATE KEY-----"
       end

       it 'should get just a public key when trying to GET a public key' do
           got = put('/environments/anenv')
           got.status.should == 201

           got = get('/crypt/anenv/public')
           got.status.should == 200
           got.content_type.should == "text/plain"
           got.body.should.not == "[]"
           got.body.should.include "-----BEGIN "
           got.body.should.include "-----END "
           got.body.should.include " PUBLIC KEY-----"
           got.body.should.not.include " PRIVATE KEY-----"
       end

       it 'should get just a private key when trying to GET a private key' do
           got = put('/environments/anenv')
           got.status.should == 201

           got = get('/crypt/anenv/private')
           got.status.should == 200
           got.content_type.should == "text/plain"
           got.body.should.not == "[]"
           got.body.should.not.include " PUBLIC KEY-----"
           got.body.should.include "-----BEGIN "
           got.body.should.include "-----END "
           got.body.should.include " PRIVATE KEY-----"
       end

       it 'should delete an existing keypair' do
           got = put('/environments/delete_me')
           got.status.should == 201

           got = delete('/crypt/delete_me')
           got.status.should == 200

           got = get('/crypt/delete_me')
           got.status.should == 200
           got.body.should.not.include " PUBLIC KEY-----"
           got.body.should.not.include " PRIVATE KEY-----"
       end

       it 'should not delete default keys' do
           got = delete('/crypt/default')
           got.status.should == 403
       end

       it 'should not encrypt the default environment' do
           got = get('/crypt/default')
           got.status.should == 200
           got.body.should.not.include " PUBLIC KEY-----"
           got.body.should.not.include " PRIVATE KEY-----"
       end

    it 'should generate new keypair for an existing environment' do
        got = put('/environments/updatemykeys')
        got.status.should == 201

        old_priv = get('/crypt/updatemykeys/private')
        old_priv.status.should == 200

        old_pub = get('/crypt/updatemykeys/public')
        old_pub.status.should == 200

        old_pub.body.should.not.equal? old_priv.body

        got = post('/crypt/updatemykeys', '')
        got.status.should == 201

        got = get('/crypt/updatemykeys')
        got.status.should == 200
        got.body.should.include " PUBLIC KEY-----"
        got.body.should.include " PRIVATE KEY-----"

        new_priv = get('/crypt/updatemykeys/private')
        new_priv.status.should == 200
        new_priv.body.should.not.equal? old_priv.body

        new_pub = get('/crypt/updatemykeys/public')
        new_pub.status.should == 200
        new_pub.body.should.not.equal? old_pub.body

        new_pub.body.should.not.equal? new_priv.body
    end

    it 'should upload new keypair for an existing environment' do
        got = put('/environments/updatemykeys')
        got.status.should == 201

        old_key = OpenSSL::PKey::RSA.new(get('/crypt/updatemykeys/private').body)

        new_key = OpenSSL::PKey::RSA.generate(512)

        got = post('/crypt/updatemykeys', new_key.to_pem)
        got.status.should == 201

        got = get('/crypt/updatemykeys/public')
        got.status.should == 200
        got.body.should == new_key.public_key.to_pem.strip!
        got.body.should.not == old_key.public_key.to_pem.strip!

        got = get('/crypt/updatemykeys/private')
        got.status.should == 200
        got.body.should == new_key.to_pem.strip!
        got.body.should.not == old_key.to_pem.strip!
    end

    it 'should generate a new keypair on demand if one is not supplied' do
        got = put('/environments/updatemykeys')
        got.status.should == 201

        old_key = OpenSSL::PKey::RSA.new(get('/crypt/updatemykeys/private').body)

        got = post('/crypt/updatemykeys')
        got.status.should == 201

        got = get('/crypt/updatemykeys/public')
        got.status.should == 200
        got.body.should.not == old_key.public_key.to_pem.strip!

        got = get('/crypt/updatemykeys/private')
        got.status.should == 200
        got.body.should.not == old_key.to_pem.strip!
    end

    it 'should reject invalid key' do
        got = put('/environments/updatemykeys')
        got.status.should == 201

        old_key = OpenSSL::PKey::RSA.new(get('/crypt/updatemykeys/private').body)

        new_key = "Sheep"

        got = post('/crypt/updatemykeys/', new_key)
        got.status.should == 406
    end
end
