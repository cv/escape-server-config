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

require 'rubygems'

gem 'ramaze', '=2009.06.12'
require 'ramaze'

require 'openssl'
require 'base64'
require 'digest/md5'

class EscController < Ramaze::Controller
    private

    # Get instance info
    def get_env(fail_on_error = true)
        @my_env = Environment[:name => @env]
        respond("Environment '#{@env}' does not exist.", 404) if @my_env.nil? and fail_on_error
        @envId = @my_env[:id] unless @my_env.nil?
        @defaultId = Environment[:name => "default"][:id]
    end

    def get_app(fail_on_error = true)
        @my_app = App[:name => @app]
        respond("Application '#{@app}' does not exist.", 404) if @my_app.nil? and fail_on_error
        @appId = @my_app[:id] unless @my_app.nil?
    end

    def get_key(fail_on_error = true)
        @myKey = Key[:name => @key, :app_id => @appId]
        respond("There is no key '#{@key}' for Application '#{@app}' in Environment '#{@env}'.", 404) if @myKey.nil? and fail_on_error
        @keyId = @myKey[:id] unless @myKey.nil?
    end

    def create_crypto_keys
        # Create a keypair
        if @env == "default"
            respond("Default environment doesn't have encryption", 401)
        end

        key = OpenSSL::PKey::RSA.generate(512)
        private_key = key.to_pem
        public_key = key.public_key.to_pem
        @my_env.update(:private_key => private_key, :public_key => public_key)
        response.status = 201
        response.headers["Content-Type"] = "text/plain"
        return public_key + "\n" + private_key
    end

    def check_auth(id = nil, realm = "")
        if id == "nobody"
            return id
        end

        response['WWW-Authenticate'] = "Basic realm=\"ESCAPE Server - #{realm}\""

        if auth = request.env['HTTP_AUTHORIZATION']
            (user, pass) = Base64.decode64(auth.split(" ")[1]).split(':')
            id = user if id.nil?
            owner = Owner[:name => user]
            if owner && (owner.password == Digest::MD5.hexdigest(pass)) && (id == user)
                return user
            end
        end

        respond 'Unauthorized', 401
    end

    def get_env_auth
        check_auth(nil, "Environment #{@env}")
    end

    def check_env_auth
        check_auth(@my_env.owner.name, "Environment #{@env}")
    end

    def checkUserAuth
        check_auth(@name, "User #{@name}")
    end
end

# Here go your requires for subclasses of Controller:
require 'controller/main'
require 'controller/environments'
require 'controller/crypt'
require 'controller/owner'
require 'controller/user'
require 'controller/auth'
require 'controller/search'

