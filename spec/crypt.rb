#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'

describe CryptController, 'Encryption bits' do
    behaves_like 'http', 'db_helper'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

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

           got = post('/crypt/updatemykeys', :input => mykeypair)
           got.status.should == 201
           
           got = get('/crypt/updatemykeys/public')
           got.status.should == 200
           got.body.should.include "-----BEGIN "
           got.body.should.include " PUBLIC KEY-----"
           got.body.should.include "MEgCQQCsEJqRpZbUL8jDKuz8O651LDSI50/7nE5EzI+1IussWGpDgrm5mNtEJayK"
           got.body.should.include "EZqWGC3Xv+7YOiW+naT3Uuwpv8uzAgMBAAE="
           got.body.should.include "-----END "
           got.body.should.not.include " PRIVATE KEY-----"
           got.body.should.not.include "MIIBOgIBAAJBAKwQmpGlltQvyMMq7Pw7rnUsNIjnT/ucTkTMj7Ui6yxYakOCubmY"
           got.body.should.not.include "20QlrIoRmpYYLde/7tg6Jb6dpPdS7Cm/y7MCAwEAAQJAT2F9nfISCqRc78Vu/dMe"
           got.body.should.not.include "4knZlst4d/Edntns9rk8XAFQpXo8NyX1WIQvzfZFF4vuzw7eBSkADkV+2+EH5kuU"
           got.body.should.not.include "6QIhANJlI/W8w0CpwO0r0rYm7PUvB2EirNluzSu1peANJme1AiEA0VyDPnoCWQ5T"
           got.body.should.not.include "6ZMuR5N1TfzPPGrOFffc5MaiY6QRNscCICO6Sx36vQlpCjr8Ox71gz2ri8xB8CpI"
           got.body.should.not.include "N40Znp5qfUAVAiEAhWhfFVOn5Vm07NTlm6SCDkT3RTeFxQfhkUJlvfqRIYcCIHjk"
           got.body.should.not.include "kFDyd3XHD/9WeQfPCMX7iODSLXzvU6HuVzsn5T6X"
           
           got = get('/crypt/updatemykeys/private')
           got.status.should == 200
           got.body.should.not.include " PUBLIC KEY-----"
           got.body.should.not.include "MEgCQQCsEJqRpZbUL8jDKuz8O651LDSI50/7nE5EzI+1IussWGpDgrm5mNtEJay"
           got.body.should.not.include "KEZqWGC3Xv+7YOiW+naT3Uuwpv8uzAgMBAAE="
           got.body.should.include "-----BEGIN "
           got.body.should.include " PRIVATE KEY-----"
           got.body.should.include "MIIBOgIBAAJBAKwQmpGlltQvyMMq7Pw7rnUsNIjnT/ucTkTMj7Ui6yxYakOCubmY"
           got.body.should.include "20QlrIoRmpYYLde/7tg6Jb6dpPdS7Cm/y7MCAwEAAQJAT2F9nfISCqRc78Vu/dMe"
           got.body.should.include "4knZlst4d/Edntns9rk8XAFQpXo8NyX1WIQvzfZFF4vuzw7eBSkADkV+2+EH5kuU"
           got.body.should.include "6QIhANJlI/W8w0CpwO0r0rYm7PUvB2EirNluzSu1peANJme1AiEA0VyDPnoCWQ5T"
           got.body.should.include "6ZMuR5N1TfzPPGrOFffc5MaiY6QRNscCICO6Sx36vQlpCjr8Ox71gz2ri8xB8CpI"
           got.body.should.include "N40Znp5qfUAVAiEAhWhfFVOn5Vm07NTlm6SCDkT3RTeFxQfhkUJlvfqRIYcCIHjk"
           got.body.should.include "kFDyd3XHD/9WeQfPCMX7iODSLXzvU6HuVzsn5T6X"
           got.body.should.include "-----END "
       end

       it 'should reject broken keypair' do
           got = put('/environments/updatemykeys')
           got.status.should == 201

           mykeypair = "
-----BEGIN RSA PUBLIC KEY-----
MEgCQQClNadbDEn4rTUOecvLRwpT4HzYbvCJ3Cvt5zEj0WbAzBRdQ9uHyOSMENSw
+TScQLPOid9vFjgB/K/4FiE4OJEHAgMBAAE=
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

            got = post('/crypt/updatemykeys/', :input => mykeypair)
            got.status.should == 500
        end
end
