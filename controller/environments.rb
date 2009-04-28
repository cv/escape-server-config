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
            response.status = 403
            return "Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        end

        if app && (not app =~ /\A[.a-zA-Z0-9_-]+\Z/)
            response.status = 403
            return "Invalid application name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        end

        if key && (not key =~ /\A[.a-zA-Z0-9_-]+\Z/)
            response.status = 403
            return "Invalid key name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        end

        # Getting...
        if request.get?
            # List all environments
            if env.nil?
                listEnvs()
            # List all apps in specified environment
            elsif app.nil?
                listApps(env)
            # List keys and values for app in environment
            elsif key.nil?
                listKeys(env, app)
            # We're getting value for specific key
            else 
                getValue(env, app, key)
            end

        # Copying...
        elsif request.post?
            # Undefined
            if env.nil?
                response.status = 400
            # You're copying an env
            elsif app.nil?
                if request.env['HTTP_CONTENT_LOCATION']
                    # We can copy to Location:
                    copyEnv(env,request.env['HTTP_CONTENT_LOCATION'])
                    response.status = 201 
                else
                    response.status = 406
                    return "Missing Location header. Can't copy environment"
                end
            end

        # Creating...
        elsif request.put?
            # Undefined
            if env.nil?
                response.status = 400
            # You're creating a new env
            elsif app.nil?
                createEnv(env)
            # You're creating a new app
            elsif key.nil?
                createApp(env, app)
            # Key stuff
            else
                if request.env['QUERY_STRING'] =~ /encrypt/
                    encryption = "encrypt"
                else
                    encryption = 'none'
                end
                value = request.body.read
                setValue(env, app, key, value, encryption)
            end

        # Deleting...
        elsif request.delete?
            # Undefined
            if env.nil?
                response.status = 400
            # You're deleting an env
            elsif app.nil?
                deleteEnv(env)
            # You're deleting an app
            elsif key.nil?
                deleteApp(env, app)
            # You're deleting a key
            else             
                deleteKey(env, app, key)
            end
        end
    end

    private

    #
    # Deletion
    #

    def deleteEnv(env)
        if env == "default"
            response.status = 403
            return "Not allowed to delete default environment!"
        end

        myEnv = Environment[:name => env]
        if myEnv
            check_auth(myEnv.owner.name, env)
            myEnv.delete
            response.status = 200
            return "Environment '#{env}' deleted."
        else
            response.status = 404
            return "Environment '#{env}' does not exist."
        end
    end

    def deleteApp(env, app)
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        end

        myapp = App[:name => app]
        if myapp.nil?
            response.status = 404
            return "Application '#{app}' does not exist."
        end

        if env == "default"
            myapp.delete
            response.status = 200
            return "Applicaton '#{app}' deleted."
        else         
            check_auth(myenv.owner.name, env)
            myapp.remove_environment(myenv)
            response.status = 200
            return "Application '#{app}' deleted from the '#{env}' environment."
        end
    end

    def deleteKey(env, app, key)
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        end

        myapp = App[:name => app]
        if myapp.nil?
            response.status = 404
            return "Application '#{app}' does not exist."
        end
        
        mykey = Key[:name => key, :app_id => myapp[:id]]
        if mykey.nil?
            response.status = 404
            return "Key '#{key}' does not exist."
        end

        if env == "default"
            # Don't delete default if we have a value set in a non-default env
            set = false
            mykey.app.environments.each do |appenv|
                if (not Value[:key_id => mykey[:id], :environment_id => appenv[:id]].nil?) and (appenv.name != "default")
                    set = true
                    break
                end
            end
            
            if not set
                mykey.delete
                response.status = 200
                return "Key '#{key}' deleted."
            else
                response.status = 403
                return "Key #{key} can't be deleted. It has values set."
            end
        else         
            check_auth(myenv.owner.name, env)
            myvalue = Value[:key_id => mykey[:id], :environment_id => myenv[:id]]
            if myvalue.nil?
                response.status = 404
                msg = "Key '#{key}' has no value in the '#{env}' environment."
            else
                myvalue.delete
                response.status = 200
                msg = "Key '#{key}' deleted from the '#{env}' environment."
            end
            return msg
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

    def listApps(env)
        # List all apps in specified environment
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        else
            apps = Array.new
            myenv.apps.each do |app|
                apps.push(app[:name])
            end
            response.headers["Content-Type"] = "application/json"
            return apps.sort.to_json
        end
    end
    
    def listKeys(env, app, getDefaults = true)
        # List keys and values for app in environment
        myenv = Environment[:name => env]
        if myenv.nil? # Env does not exist
            response.status = 404
            return "Environment '#{env}' does not exist."
        end

        myapp = App[:name => app]

        if myapp.nil?
            response.status = 404
            return "Application '#{app}' does not exist."
        elsif myenv.apps.include? myapp
            pairs = Array.new
            myapp.keys.each do |key|
                value = Value[:key_id => key[:id], :environment_id => myenv[:id]]
                if value.nil? && getDefaults # Got no value in specified env, what's in default and do we want defaults?
                    value = Value[:key_id => key[:id], :environment_id => Environment[:name => "default"][:id]]
                end
                if not value.nil?
                    pairs.push("#{key[:name]}=#{value[:value].gsub("\n", "")}\n")
                end
            end
            response.headers["Content-Type"] = "text/plain"
            return pairs.sort
        else
            response.status = 404
            return "Application '#{app}' is not included in Environment '#{env}'."
        end
    end


    def getValue(env, app, key, getDefaults = true)
        myapp = App[:name => app]
        if myapp.nil?
            response.status = 404
            return "Application '#{app}' does not exist."
        end

        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        end

        if not myenv.apps.include?(myapp)
            response.status = 404
            return "Application '#{app}' is not included in Environment '#{env}'."
        end

        mykey = Key[:name => key, :app_id => myapp[:id]]
        if mykey.nil?
            response.status = 404
            return "There is no key '#{key}' for Application '#{app}' in Environment '#{env}'."
        end

        value = Value[:key_id => mykey[:id], :environment_id => myenv[:id]]
        if value.nil? && getDefaults # No value for this env, is there one for default and do we want defaults?
            value = Value[:key_id => mykey[:id], :environment_id => Environment[:name => "default"][:id]]
            if value.nil? # No default value...
                response.status = 404
                return "No default value"
            end
        end

        response.headers["Content-Type"] = "text/plain"
        return value[:value]
    end

    #
    # Creaters
    #

    def createEnv(env)
        if Environment[:name => env]
            response.status = 200
            return "Environment '#{env}' already exists."
        else
            Environment.create(:name => env)
            createCryptoKeys(env,"pair")      
            response.status = 201
            return "Environment created."
        end
    end

    def createApp(env, app)
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist"
        end

        check_auth(myenv.owner.name, env)

        msg = nil
        myapp = App[:name => app]
        if myapp.nil?
            myapp = App.create(:name => app)

            response.status = 201
            msg = "Application '#{app}' created."
        else
            response.status = 200
            msg = "Application '#{app}' already exists."
        end

        myenv.add_app(myapp) unless myenv.apps.include?(myapp)

        return msg
    end

    def setValue(env, app, key, value, encryption = "none")
        myapp = App[:name => app]
        if myapp.nil?
            response.status = 404
            return "Application '#{app}' does not exist."
        end

        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        end

        check_auth(myenv.owner.name, env)

        encrypted = false
        if encryption == "encrypt"
            # Do some encryption
            public_key = OpenSSL::PKey::RSA.new(myenv.public_key)
            encrypted_value = Base64.encode64(public_key.public_encrypt(value)).strip()
            value = encrypted_value
        end
        
        if encryption != "none"
            encrypted = true
        end

        mykey = Key[:name => key, :app_id => myapp[:id]]
        # New one, let's create
        if mykey.nil?
            mykey = Key.create(:name => key, :app_id => myapp[:id])
            myapp.add_key(mykey)
            defaultenv = Environment[:name => 'default']
            Value.create(:key_id => mykey[:id], :environment_id => defaultenv[:id], :value => value, :is_encrypted => encrypted)
            Value.create(:key_id => mykey[:id], :environment_id => myenv[:id], :value => value, :is_encrypted => encrypted)
            response.status = 201
        # We're updating the config
        else             
            myvalue = Value[:key_id => mykey[:id], :environment_id => myenv[:id]]
            if myvalue.nil? # New value...
                Value.create(:key_id => mykey[:id], :environment_id => myenv[:id], :value => value, :is_encrypted => encrypted)
                response.status = 201
            else # Updating the value
                myvalue.update(:value => value)
                response.status = 200
            end
        end
    end
    
    def copyEnv(fromEnv,toEnv)
        # Create new env
        createEnv(toEnv)
        # Copy applications into new env
        allExistingApps = JSON.parse(listApps(fromEnv))
        allExistingApps.each do |existingApp|
            createApp(toEnv, existingApp)
            allExistingValues = listKeys(fromEnv, existingApp, false)
            allExistingValues.each do |line|
                (key, value) = line.chomp.split('=', 2)
                setValue(toEnv, existingApp, key, value)
            end
        end
    end

end    

