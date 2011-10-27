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
            @key = request.body.read
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
            @myEnv.update(:private_key => nil, :public_key => nil)
            response.status = 200
        end
    end

    def updateCryptoKeys
        if @env == "default"
            respond("Can't put keys into default environment.", 403)
        else
            getEnv
            checkEnvAuth

            if @key && @key != ''
                # Updating with provided values
                begin
                    new_private_key = OpenSSL::PKey::RSA.new(@key)
                rescue
                    respond("Error in key", 406)
                end

                @myEnv.update(:private_key => new_private_key.to_pem, :public_key => new_private_key.public_key.to_pem)
                respond("Updated key", 201)
            else
                # Creating new keys
                createCryptoKeys
                response.status = 201
            end
        end
    end

end
