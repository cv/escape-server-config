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

    def getEnv(failOnError = true)
        @myEnv = Environment[:name => @env]
        respond("Environment '#{@env}' does not exist.", 404) if @myEnv.nil? and failOnError
        @envId = @myEnv[:id] unless @myEnv.nil?
        @defaultId = Environment[:name => "default"][:id]
    end

    def getApp(failOnError = true)
        @myApp = App[:name => @app]
        respond("Application '#{@app}' does not exist.", 404) if @myApp.nil? and failOnError
        @appId = @myApp[:id] unless @myApp.nil?
    end

    def getKey(failOnError = true)
        @myKey = Key[:name => @key, :app_id => @appId]
        respond("There is no key '#{@key}' for Application '#{@app}' in Environment '#{@env}'.", 404) if @myKey.nil? and failOnError
        @keyId = @myKey[:id] unless @myKey.nil?
    end

    #
    # Deletion
    #

    def deleteEnv
        respond("Not allowed to delete default environment!", 403) if @env == "default"
        getEnv
        check_auth(@myEnv.owner.name, "Environment #{@env}")
        @myEnv.delete
        respond("Environment '#{@env}' deleted.", 200)
    end

    def deleteApp
        getApp

        if @env == "default"
            # TODO: What if this app has values in other environments???
            @myApp.delete
            respond("Applicaton '#{@app}' deleted.", 200)
        else         
            getEnv
            check_auth(@myEnv.owner.name, "Environment #{@env}")
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
            check_auth(@myEnv.owner.name, "Environment #{@env}")
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
    
    def listKeys(getDefaults = true)
        # List keys and values for app in environment
        getEnv
        getApp

        if @myEnv.apps.include? @myApp
            pairs = Array.new
            @myApp.keys.each do |key|
                value = Value[:key_id => key[:id], :environment_id => @envId]

                if value.nil? && getDefaults # Got no value in specified env, what's in default and do we want defaults?
                    value = Value[:key_id => key[:id], :environment_id => @defaultId]
                end

                if not value.nil?
                    pairs.push("#{key[:name]}=#{value[:value].gsub("\n", "")}\n")
                end
            end

            response.headers["Content-Type"] = "text/plain"
            return pairs.sort
        else
            respond("Application '#{@app}' is not included in Environment '#{@env}'.", 404)
        end
    end


    def getValue(getDefaults = true)
        getEnv
        getApp

        if not @myEnv.apps.include? @myApp
            respond("Application '#{@app}' is not included in Environment '#{@env}'.", 404)
        end

        getKey(false)

        value = Value[:key_id => @keyId, :environment_id => @myEnv[:id]]
        if value.nil? && getDefaults # No value for this env, is there one for default and do we want defaults?
            value = Value[:key_id => @keyId, :environment_id => @defaultId]
            if value.nil? # No default value...
                respond("No default value", 404)
            end
        end

        response.headers["Content-Type"] = "text/plain"
        return value[:value]
    end

    #
    # Creaters
    #

    def createEnv
        respond("Environment '#{@env}' already exists.", 200) if Environment[:name => @env]

        @myEnv = Environment.create(:name => @env)
        createCryptoKeys(@env, "pair")      
        respond("Environment created.", 201)
    end

    def createApp
        getEnv
        check_auth(@myEnv.owner.name, "Environment #{@env}")
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
        check_auth(@myEnv.owner.name, "Environment #{@env}")
        getApp

        value = request.body.read
        if request.env['QUERY_STRING'] =~ /encrypt/
            encrypted = true
            # Do some encryption
            public_key = OpenSSL::PKey::RSA.new(@myEnv.public_key)
            encrypted_value = Base64.encode64(public_key.public_encrypt(value)).strip()
            value = encrypted_value
        else
            encrypted = false
        end

        myKey = Key[:name => @key, :app_id => @appId]
        # New one, let's create
        if myKey.nil?
            myKey = Key.create(:name => @key, :app_id => @appId)
            @myApp.add_key(myKey)
            Value.create(:key_id => myKey[:id], :environment_id => @defaultId, :value => value, :is_encrypted => encrypted)
            Value.create(:key_id => myKey[:id], :environment_id => @envId, :value => value, :is_encrypted => encrypted)
            response.status = 201
        # We're updating the config
        else             
            myValue = Value[:key_id => myKey[:id], :environment_id => @envId]
            if myValue.nil? # New value...
                Value.create(:key_id => myKey[:id], :environment_id => @envId, :value => value, :is_encrypted => encrypted)
                respond("Created key '#{@key}", 201)
            else # Updating the value
                myValue.update(:value => value, :is_encrypted => encrypted)
                respond("Updated key '#{@key}", 200)
            end
        end
    end
    
    def copyEnv
        respond("Missing Location header. Can't copy environment", 406) unless request.env['HTTP_CONTENT_LOCATION']

        srcEnv = Environment[:name => request.env['HTTP_CONTENT_LOCATION']]
        respond("Source environment '#{request.env['HTTP_CONTENT_LOCATION']}' does not exist.", 404) if srcEnv.nil?

        getEnv(false)
        respond("Target environment #{@env} already exists.", 409) unless @myEnv.nil?

        # Create new env
        @myEnv = Environment.create(:name => @env)
        createCryptoKeys(@env, "pair")      

        srcEnvId = srcEnv[:id]
        destEnvId = @myEnv[:id]
        # Copy applications into new env
        srcEnv.apps.each do |existingApp|
            @myEnv.add_app(existingApp)
            # Copy overridden values
            p " - Checking override values for app '#{existingApp[:name]}'"
            existingApp.keys.each do |key|
                value = Value[:key_id => key[:id], :environment_id => srcEnvId]
                Value.create(:key_id => key[:id], :environment_id => destEnvId, :value => value[:value], :is_encrypted => value[:is_encrypted]) unless value.nil?
            end
        end
    end
end    

