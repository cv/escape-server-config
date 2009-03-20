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
require 'md5'

class EscController < Ramaze::Controller
    private

    def createCryptoKeys(env, pair)
        # Create a keypair
        if env == "default"
            response.status = 401
            return "Default environment doesn't have encryption"
        end
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        elsif pair == "pair"
            key = OpenSSL::PKey::RSA.generate(512)
            public_key = key.public_key.to_pem
            private_key = key.to_pem 
            myenv.update(:public_key => public_key, :private_key => private_key)
            response.status = 201
            response.headers["Content-Type"] = "text/plain" 
            return public_key + "\n" + private_key
        else
            response.status = 403
            return "Can only create keys in pairs"
        end
    end
  

    def check_auth(id = nil, env = "")
        response['WWW-Authenticate'] = "Basic realm=\"ESCAPE Server - #{env}\""

        if auth = request.env['HTTP_AUTHORIZATION']
            (user, pass) = Base64.decode64(auth).split(':')
            id = user if id.nil?
            owner = Owner[:name => user]
            if owner && (owner.password == MD5.hexdigest(pass)) && (id == user)
                return user
            end
        end

        respond 'Unauthorized', 401
    end
end

# Here go your requires for subclasses of Controller:
require 'controller/main'
require 'controller/environments'
require 'controller/crypt'
require 'controller/owner'
require 'controller/user'
require 'controller/auth'

