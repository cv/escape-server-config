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

require 'json'
require 'openssl'
require 'time'

class EnvironmentsController < EscController
    map('/environments')

    def index(env = nil, app = nil, key = nil)
        # Sanity check what we've got first
        if env && (not env =~ /\A[.a-zA-Z0-9_-]+\Z/)
            respond("Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403)
        end

        if app && (not app =~ /\A[.a-zA-Z0-9_-]+\Z/)
            respond("Invalid application name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403)
        end

        if key && (not key =~ /\A[.a-zA-Z0-9_-]+\Z/)
            respond("Invalid key name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403)
        end

        @env = env
        @app = app
        @key = key

        # Getting...
        if request.get?
            # List all environments
            if env.nil?
                list_envs
            # List all apps in specified environment
            elsif app.nil?
                listApps
            # List keys and values for app in environment
            elsif key.nil?
                listKeys
            # We're getting value for specific key
            else
                getValue
            end

        # Copying...
        elsif request.post?
            # Undefined
            if env.nil?
                respond("Undefined", 400)
            # You're copying an env
            elsif app.nil?
                # env is the target, Location Header has the source
                copyEnv
            end

        # Creating...
        elsif request.put?
            # Undefined
            if env.nil?
                response.status = 400
            # You're creating a new env
            elsif app.nil?
                createEnv
            # You're creating a new app
            elsif key.nil?
                createApp
            # Key stuff
            else
                setValue
            end

        # Deleting...
        elsif request.delete?
            # Undefined
            if env.nil?
                response.status = 400
            # You're deleting an env
            elsif app.nil?
                delete_env
            # You're deleting an app
            elsif key.nil?
                delete_app
            # You're deleting a key
            else
                delete_key
            end
        end
    end

    private

    #
    # Deletion
    #

    def delete_env
        respond("Not allowed to delete default environment!", 403) if @env == "default"
        get_env
        check_env_auth
        @my_env.delete
        respond("Environment '#{@env}' deleted.", 200)
    end

    def delete_app
        get_app

        if @env == "default"
            if @my_app.environments.size == 1
                @my_app.delete
                respond("Applicaton '#{@app}' deleted.", 200)
            else
                respond("Applicaton '#{@app}' is used in other environments.", 412)
            end
        else
            get_env
            check_env_auth
            @my_app.remove_environment(@my_env)
            respond("Application '#{@app}' deleted from the '#{@env}' environment.", 200)
        end
    end

    def delete_key
        get_env
        get_app
        get_key

        if @env == "default"
            # Don't delete default if we have a value set in a non-default env
            set = false
            @myKey.app.environments.each do |appenv|
                if (not Value[:key_id => @keyId, :environment_id => appenv[:id]].nil?) and (appenv.name != "default")
                    set = true
                    break
                end
            end

            if not set
                @myKey.delete
                respond("Key '#{@key}' deleted from application '#{@app}'.", 200)
            else
                respond("Key #{@key} can't be deleted. It has non default values set.", 403)
            end
        else
            check_env_auth
            myValue = Value[:key_id => @keyId, :environment_id => @envId]
            if myValue.nil?
                respond("Key '#{@key}' has no value in the '#{@env}' environment.", 404)
            else
                myValue.delete
                respond("Key '#{@key}' deleted from the '#{@env}' environment.", 200)
            end
        end

    end

    #
    # Getters
    #

    def check_last_modified(modified)
        return false unless request.env['HTTP_IF_MODIFIED_SINCE']

        if (modified <= Time.parse(request.env['HTTP_IF_MODIFIED_SINCE']))
            response.status = 304
            return true
        end

        return false
    end

    def list_envs
        envs = Array.new
        Environment.all.each do |env|
            envs.push(env[:name])
        end
        response.headers["Content-Type"] = "application/json"
        return envs.sort.to_json
    end

    def listApps
        # List all apps in specified environment
        get_env

        apps = Array.new
        @my_env.apps.each do |app|
            apps.push(app[:name])
        end

        response.headers["Content-Type"] = "application/json"
        return apps.sort.to_json
    end

    def listKeys
        # List keys and values for app in environment
        get_env
        get_app

        if @my_env.apps.include? @my_app
            pairs = Array.new
            defaults = Array.new
            overrides = Array.new
            encrypted = Array.new
            modified = Array.new
            @my_app.keys.each do |key|
                value = Value[:key_id => key[:id], :environment_id => @envId]

                if value.nil? # Got no value in specified env, what's in default and do we want defaults?
                    value = Value[:key_id => key[:id], :environment_id => @defaultId]
                    defaults.push(key[:name])
                else
                    overrides.push(key[:name])
                end

                encrypted.push(key[:name]) if value[:is_encrypted]
                pairs.push("#{key[:name]}=#{value[:value].gsub("\n", "")}\n")
                modified.push(value[:modified])
            end

            #return nil if check_last_modified(modified.max)

            response.headers["Content-Type"] = "text/plain"
            response.headers["X-Default-Values"] = defaults.sort.to_json
            response.headers["X-Override-Values"] = overrides.sort.to_json
            response.headers["X-Encrypted"] = encrypted.sort.to_json
            response.headers["Last-Modified"] = modified.max.httpdate unless modified.empty?

            return pairs.sort
        else
            respond("Application '#{@app}' is not included in Environment '#{@env}'.", 404)
        end
    end

    def getValue
        get_env
        get_app

        if not @my_env.apps.include? @my_app
            respond("Application '#{@app}' is not included in Environment '#{@env}'.", 404)
        end

        get_key(false)

        value = @my_app.get_key_value(@myKey, @my_env)
        if value.nil?
            respond("No default value", 404)
        else
            if value.default?
                response.headers["X-Value-Type"] = "default"
            else
                response.headers["X-Value-Type"] = "override"
            end
        end

        #check_last_modified(value[:modified])

        if value[:is_encrypted]
            response.headers["Content-Type"] = "application/octet-stream"
            response.headers["Content-Transfer-Encoding"] = "base64"
        else
            response.headers["Content-Type"] = "text/plain"
        end

        response.headers["Last-Modified"] = value[:modified].httpdate
        return value[:value]
    end

    #
    # Creaters
    #

    def createEnv
        respond("Environment '#{@env}' already exists.", 200) if Environment[:name => @env]

        @my_env = Environment.create(:name => @env)
        @pair = "pair"
        create_crypto_keys
        respond("Environment created.", 201)
    end

    def createApp
        get_env
        check_env_auth
        get_app(false)
        respond("Application '#{@app}' already exists in environment '#{@env}'.", 200) if @my_app and @my_app.environments.include? @my_env

        if @my_app.nil?
            @my_app = App.create(:name => @app)
        end
        @my_env.add_app(@my_app) unless @my_env.apps.include? @my_app

        respond("Application '#{@app}' created in environment '#{@env}'.", 201)
    end

    def setValue
        get_env
        check_env_auth
        get_app

        value = request.body.read
        if request.env['QUERY_STRING'] =~ /encrypt/
            respond("Can't encrypt data in the default environment", 412) if @env == "default"
            encrypted = true
            # Do some encryption
            public_key = OpenSSL::PKey::RSA.new(@my_env.public_key)
            encrypted_value = Base64.encode64(public_key.public_encrypt(value)).strip()
            value = encrypted_value
        else
            encrypted = false
        end

        if @my_app.set_key_value(@key, @my_env, value, encrypted)
          respond("Created key '#{@key}", 201)
        else
          respond("Updated key '#{@key}", 200)
        end
    end

    def copyEnv
        respond("Missing Content-Location header. Can't copy environment", 406) unless request.env['HTTP_CONTENT_LOCATION']

        srcEnv = Environment[:name => request.env['HTTP_CONTENT_LOCATION']]
        respond("Source environment '#{request.env['HTTP_CONTENT_LOCATION']}' does not exist.", 404) if srcEnv.nil?

        get_env(false)
        respond("Target environment #{@env} already exists.", 409) unless @my_env.nil?

        # Create new env
        @my_env = Environment.create(:name => @env)
        @pair = "pair"
        create_crypto_keys

        srcEnvId = srcEnv[:id]
        destEnvId = @my_env[:id]
        # Copy applications into new env
        srcEnv.apps.each do |existingApp|
            @my_env.add_app(existingApp)
            # Copy overridden values
            existingApp.keys.each do |key|
                value = Value[:key_id => key[:id], :environment_id => srcEnvId]
                Value.create(:key_id => key[:id], :environment_id => destEnvId, :value => value[:value], :is_encrypted => value[:is_encrypted]) unless value.nil?
            end
        end
    end
end

