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
                listEnvs
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
                deleteEnv
            # You're deleting an app
            elsif key.nil?
                deleteApp
            # You're deleting a key
            else             
                deleteKey
            end
        end
    end

    private

    #
    # Deletion
    #

    def deleteEnv
        respond("Not allowed to delete default environment!", 403) if @env == "default"
        getEnv
        checkEnvAuth
        @myEnv.delete
        respond("Environment '#{@env}' deleted.", 200)
    end

    def deleteApp
        getApp

        if @env == "default"
            if @myApp.environments.size == 1 
                @myApp.delete
                respond("Applicaton '#{@app}' deleted.", 200)
            else
                respond("Applicaton '#{@app}' is used in other environments.", 412)
            end
        else         
            getEnv
            checkEnvAuth
            @myApp.remove_environment(@myEnv)
            respond("Application '#{@app}' deleted from the '#{@env}' environment.", 200)
        end
    end

    def deleteKey
        getEnv
        getApp
        getKey

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
            checkEnvAuth
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

    def listEnvs
        envs = Array.new
        Environment.all.each do |env|
            envs.push(env[:name])
        end
        response.headers["Content-Type"] = "application/json"
        return envs.sort.to_json
    end

    def listApps
        # List all apps in specified environment
        getEnv

        apps = Array.new
        @myEnv.apps.each do |app|
            apps.push(app[:name])
        end

        response.headers["Content-Type"] = "application/json"
        return apps.sort.to_json
    end
    
    def listKeys
        # List keys and values for app in environment
        getEnv
        getApp

        if @myEnv.apps.include? @myApp
            pairs = Array.new
            defaults = Array.new
            overrides = Array.new
            encrypted = Array.new
            @myApp.keys.each do |key|
                value = Value[:key_id => key[:id], :environment_id => @envId]

                if value.nil? # Got no value in specified env, what's in default and do we want defaults?
                    value = Value[:key_id => key[:id], :environment_id => @defaultId]
                    defaults.push(key[:name])
                else
                    overrides.push(key[:name])
                end
                
                encrypted.push(key[:name]) if value[:is_encrypted]
                pairs.push("#{key[:name]}=#{value[:value].gsub("\n", "")}\n")
            end

            response.headers["Content-Type"] = "text/plain"
            response.headers["X-Default-Values"] = defaults.sort.to_json
            response.headers["X-Override-Values"] = overrides.sort.to_json
            response.headers["X-Encrypted"] = encrypted.sort.to_json
            return pairs.sort
        else
            respond("Application '#{@app}' is not included in Environment '#{@env}'.", 404)
        end
    end


    def getValue
        getEnv
        getApp

        if not @myEnv.apps.include? @myApp
            respond("Application '#{@app}' is not included in Environment '#{@env}'.", 404)
        end

        getKey(false)

        value = @myApp.get_key_value(@myKey, @myEnv)
        if value.nil?
            respond("No default value", 404)
        else
            if value.default?
                response.headers["X-Value-Type"] = "default"
            else
                response.headers["X-Value-Type"] = "override"
            end
        end

        if value[:is_encrypted]
            response.headers["Content-Type"] = "application/octet-stream"
            response.headers["Content-Transfer-Encoding"] = "base64"
        else
            response.headers["Content-Type"] = "text/plain"
        end

        return value[:value]
    end

    #
    # Creaters
    #

    def createEnv
        respond("Environment '#{@env}' already exists.", 200) if Environment[:name => @env]

        @myEnv = Environment.create(:name => @env)
        @pair = "pair"
        createCryptoKeys
        respond("Environment created.", 201)
    end

    def createApp
        getEnv
        checkEnvAuth
        getApp(false)
        respond("Application '#{@app}' already exists in environment '#{@env}'.", 200) if @myApp and @myApp.environments.include? @myEnv

        if @myApp.nil?
            @myApp = App.create(:name => @app)
        end
        @myEnv.add_app(@myApp) unless @myEnv.apps.include? @myApp

        respond("Application '#{@app}' created in environment '#{@env}'.", 201)
    end

    def setValue
        getEnv
        checkEnvAuth
        getApp

        value = request.body.read
        if request.env['QUERY_STRING'] =~ /encrypt/
            respond("Can't encrypt data in the default environment", 412) if @env == "default"
            encrypted = true
            # Do some encryption
            public_key = OpenSSL::PKey::RSA.new(@myEnv.public_key)
            encrypted_value = Base64.encode64(public_key.public_encrypt(value)).strip()
            value = encrypted_value
        else
            encrypted = false
        end

        if @myApp.set_key_value(@key, @myEnv, value, encrypted)
          respond("Created key '#{@key}", 201)
        else
          respond("Updated key '#{@key}", 200)
        end
    end
    
    def copyEnv
        respond("Missing Content-Location header. Can't copy environment", 406) unless request.env['HTTP_CONTENT_LOCATION']

        srcEnv = Environment[:name => request.env['HTTP_CONTENT_LOCATION']]
        respond("Source environment '#{request.env['HTTP_CONTENT_LOCATION']}' does not exist.", 404) if srcEnv.nil?

        getEnv(false)
        respond("Target environment #{@env} already exists.", 409) unless @myEnv.nil?

        # Create new env
        @myEnv = Environment.create(:name => @env)
        @pair = "pair"
        createCryptoKeys

        srcEnvId = srcEnv[:id]
        destEnvId = @myEnv[:id]
        # Copy applications into new env
        srcEnv.apps.each do |existingApp|
            @myEnv.add_app(existingApp)
            # Copy overridden values
            existingApp.keys.each do |key|
                value = Value[:key_id => key[:id], :environment_id => srcEnvId]
                Value.create(:key_id => key[:id], :environment_id => destEnvId, :value => value[:value], :is_encrypted => value[:is_encrypted]) unless value.nil?
            end
        end
    end
end    

