#   Copyright 2009 ThoughtWorks
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'openssl'
require 'base64'

class CryptController < EscController
    map('/crypt')

    def index(env = nil, puborpriv = nil)
        if env.nil?
            respond("Must supply and environment", 400)
        end

        # Sanity check what we've got first
        if env && (not env =~ /\A[.a-zA-Z0-9_-]+\Z/)
            respond("Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403)
        end

        if puborpriv && (puborpriv != "public") && (puborpriv != "private")
            respond("Must define keytype as either public or private", 403)
        end

        puborpriv = "pair" if puborpriv.nil?
        @pair = puborpriv

        @env = env

        # Getting...
        if request.get?
            showCryptoKeys
        # Updating...
        elsif request.post?
            @keys = request.body.read
            updateCryptoKeys
        # Deleting...
        elsif request.delete?
            deleteCryptoKeys
        else
            respond("Unsupported method", 405)
        end
    end

    private
    
    def showCryptoKeys
        # Show keys in an environment
        getEnv

        response.status = 200
        response.headers["Content-Type"] = "text/plain"   

        if (@pair == "pair") and (@myEnv.owner.name == "nobody")
            return "#{@myEnv.public_key}" + "\n" +  "#{@myEnv.private_key}"
        elsif (@pair == "pair") and request.env['HTTP_AUTHORIZATION']
            checkEnvAuth
            return "#{@myEnv.public_key}" + "\n" +  "#{@myEnv.private_key}"
        elsif @pair == "private"
            checkEnvAuth
            return "#{@myEnv.private_key}"
        elsif (@pair == "public") or (@pair == "pair")
            return "#{@myEnv.public_key}"
        else
            respond("Crypto keys can only be public or private or in a pair", 403)
        end
    end
    
    def deleteCryptoKeys
        if @env == "default"
            respond("Can't delete keys from default environment.", 403)
        else
            getEnv
            checkEnvAuth
            response.status = 200
            if @pair == "pair"
                @myEnv.update(:public_key => '', :private_key => '')
            elsif @pair == "private"
                @myEnv.update(:private_key => nil)
            elsif @pair == "public"
                @myEnv.update(:public_key => nil)
            else
                respond("Crypto keys can only be public or private or in a pair", 403)
            end
        end
    end
    
    def updateCryptoKeys
        if @env == "default"
            respond("Can't put keys into default environment.", 403)
        elsif @pair != "pair"
            respond("Only update keys in a pair", 403)
        else
            getEnv
            checkEnvAuth

            if @keys && @keys != ''
                # Updating with provided values
                /(-----BEGIN RSA PUBLIC KEY-----.*-----END RSA PUBLIC KEY-----)/m.match(@keys)
                public_string = $1
                /(-----BEGIN RSA PRIVATE KEY-----.*-----END RSA PRIVATE KEY-----)/m.match(@keys)
                private_string = $1
                if public_string && private_string
                    message = "Test encryption"

                    begin
                        public_key = OpenSSL::PKey::RSA.new(public_string)
                        private_key = OpenSSL::PKey::RSA.new(private_string)
                        encrypted_message = Base64.encode64(public_key.public_encrypt(message))
                        decrypted_message = private_key.private_decrypt(Base64.decode64(encrypted_message))
                    rescue
                        respond("Error in keys", 406)
                    end

                    if message == decrypted_message
                        @myEnv.update(:public_key => public_key.to_pem, :private_key => private_key.to_pem)
                        response.status = 201
                    else
                        respond("Keys are not a pair", 406)
                    end
                else
                    response.status = 501
                end
            else
                # Creating new keys
                createCryptoKeys
                response.status = 201
            end                    
        end
    end
    
end
