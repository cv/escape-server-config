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

    def index(env = nil, public_or_private = nil)
        if env.nil?
            respond("Must supply and environment", 400)
        end

        # Sanity check what we've got first
        if env && (not env =~ /\A[.a-zA-Z0-9_-]+\Z/)
            respond("Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403)
        end

        if public_or_private && (public_or_private != "public") && (public_or_private != "private")
            respond("Must define keytype as either public or private", 403)
        end

        public_or_private = "pair" if public_or_private.nil?
        @pair = public_or_private

        @env = env

        # Getting...
        if request.get?
            show_crypto_keys
        # Updating...
        elsif request.post?
            @key = request.body.read
            update_crypto_keys
        # Deleting...
        elsif request.delete?
            delete_crypto_keys
        else
            respond("Unsupported method", 405)
        end
    end

    private

    def show_crypto_keys
        # Show keys in an environment
        get_env

        response.status = 200
        response.headers["Content-Type"] = "text/plain"

        if (@pair == "pair") and (@my_env.owner.name == "nobody")
            return "#{@my_env.public_key}" + "\n" +  "#{@my_env.private_key}"
        elsif (@pair == "pair") and request.env['HTTP_AUTHORIZATION']
            check_env_auth
            return "#{@my_env.public_key}" + "\n" +  "#{@my_env.private_key}"
        elsif @pair == "private"
            check_env_auth
            return "#{@my_env.private_key}"
        elsif (@pair == "public") or (@pair == "pair")
            return "#{@my_env.public_key}"
        else
            respond("Crypto keys can only be public or private or in a pair", 403)
        end
    end

    def delete_crypto_keys
        if @env == "default"
            respond("Can't delete keys from default environment.", 403)
        else
            get_env
            check_env_auth
            @my_env.update(:private_key => nil, :public_key => nil)
            response.status = 200
        end
    end

    def update_crypto_keys
        if @env == "default"
            respond("Can't put keys into default environment.", 403)
        else
            get_env
            check_env_auth

            if @key && @key != ''
                # Updating with provided values
                begin
                    new_private_key = OpenSSL::PKey::RSA.new(@key)
                rescue
                    respond("Error in key", 406)
                end

                @my_env.update(:private_key => new_private_key.to_pem, :public_key => new_private_key.public_key.to_pem)
                respond("Updated key", 201)
            else
                # Creating new keys
                create_crypto_keys
                response.status = 201
            end
        end
    end

end
