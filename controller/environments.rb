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

class EnvironmentsController < Ramaze::Controller
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

        # Creating...
        elsif request.put? || request.post?
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
                setValue(env, app, key)
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
        elsif Environment[:name => env] 
            Environment[:name => env].delete
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
            myapp.remove_environment(myenv)
            response.status = 200
            return "Application '#{app}' deleted from the '#{env}' environment."
        end
    end

    def deleteKey(env, app, key)
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
    
    def listKeys(env, app)
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
        elsif not myapp.environments.include?(myenv)
            response.status = 404
            return "Application '#{app}' is not included in Environment '#{env}'."
        else 
            pairs = Array.new
            myapp.keys.each do |key|
                value = Value[:key_id => key[:id], :environment_id => myenv[:id]]
                if value.nil? # Got no value in specified env, what's in default?
                    value = Value[:key_id => key[:id], :environment_id => Environment[:name => "default"][:id]]
                end
                if value[:value] == "" # Got no value in specified env, what's in default?
                    value = Value[:key_id => key[:id], :environment_id => Environment[:name => "default"][:id]]
                end
                pairs.push("#{key[:name]}=#{value[:value]}\n")
            end
            response.headers["Content-Type"] = "text/plain"
            return pairs.sort
        end
    end


    def getValue(env, app, key)
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

        if not myapp.environments.include?(myenv)
            response.status = 404
            return "Application '#{app}' is not included in Environment '#{env}'."
        end

        mykey = Key[:name => key, :app_id => myapp[:id]]
        if mykey.nil?
            response.status = 404
            return "There is no key '#{key}' for Application '#{app}' in Environment '#{env}'."
        end

        value = Value[:key_id => mykey[:id], :environment_id => myenv[:id]]
        if value.nil? # No value for this env, is there one for default?
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

        msg = nil
        myapp = App[:name => app]
        if myapp.nil?
            defaultenv = Environment[:name => 'default']
            myapp = App.create(:name => app)
            myapp.add_environment(defaultenv)

            response.status = 201
            msg = "Application '#{app}' created."
        else
            response.status = 200
            msg = "Application '#{app}' already exists."
        end

        if env != 'default'
            myapp.add_environment(myenv)
        end

        return msg
    end

    def setValue(env, app, key)
        value = request.body.read
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

        mykey = Key[:name => key, :app_id => myapp[:id]]
        # New one, let's create
        if mykey.nil?
            mykey = Key.create(:name => key, :app_id => myapp[:id])
            myapp.add_key(mykey)
            defaultenv = Environment[:name => 'default']
            Value.create(:key_id => mykey[:id], :environment_id => defaultenv[:id], :value => value)
            Value.create(:key_id => mykey[:id], :environment_id => myenv[:id], :value => value)
            response.status = 201
        # We're updating the config
        else             
            myvalue = Value[:key_id => mykey[:id], :environment_id => myenv[:id]]
            if myvalue.nil? # New value...
                Value.create(:key_id => mykey[:id], :environment_id => myenv[:id], :value => value)
                response.status = 201
            else # Updating the value
                myvalue.update(:value => value)
                response.status = 200
            end
        end
    end
end
