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


        # Setting...
        elsif request.post? || request.put?
            # Undefined
            if env.nil?
                response.status = 400
            # You're putting an env
            elsif app.nil?
                createEnv(env)
            # You're putting an app
            elsif key.nil?
                createApp(env, app)
            # You're putting a value to a key
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

    def deleteEnv(env)
        msg = nil
        if not env =~ /\A[.a-zA-Z0-9_-]+\Z/
            response.status = 403
            msg = "Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        elsif env == "default"
            response.status = 403
            msg = "Not allowed to delete default environment!"
        elsif Environment[:name => env] 
            Environment[:name => env].delete
            response.status = 200
            msg = "Environment deleted."
        else
            response.status = 404
            msg = "Environment " + env + " does not exist"
        end
        return msg
    end

    def deleteApp(env, app)
        if not app =~ /\A[.a-zA-Z0-9_-]+\Z/
            response.status = 403
            return "Invalid application name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        end

        myapp = App[:name => app]
        myenv = Environment[:name => env]

        if myenv.nil?
            response.status = 404
            return "Environment #{env} does not exist"
        end

        owner = request['owner']
        if owner.nil?
            myowner = Owner[:name => "nobody"]
        else
            myowner = Owner[:name => owner]
            if myowner.nil?
                response.status = 404 if myowner.nil?
                return "Unknown owner..."
            end
        end

        if myapp.nil?
            response.status = 404
            return "Application #{app} does not exist"
        end

        if env == "default"
            myapp.delete
            response.status = 200
        else
            # This does not work. Need to talk about mapping tables.          
            # myAppEnv = AppsEnvironment[:app_id => myapp[:id], :environment_id => myenv[:id]]
            # myAppEnv.delete
            # response.status = 200
        end

    end

    def listEnvs
        envs = Array.new
        Environment.all.each do |env|
            envs.push(env[:name])
        end
        return envs.sort.to_json
    end

    def listApps(env)
        # List all apps in specified environment
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
        else
            apps = Array.new
            myenv.apps.each do |app|
                apps.push(app[:name])
            end
            return apps.sort.to_json
        end
    end

    
    def listKeys(env, app)
        # List keys and values for app in environment
        myenv = Environment[:name => env]
        myapp = App[:name => app]
        if myenv.nil? || myapp.nil? # Env does not exist
            response.status = 404
        else 
            # TODO: The next few lines are damn scary! Need some nice helper methods somewhere...
            ownermap = OwnerAppEnv[:app_id => myapp[:id], :environment_id => myenv[:id]]
            owner = Owner[:id => ownermap[:owner_id]]
            response.headers["X-Owner"] = owner[:name]
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
            return "App #{app} does not exist"
        end
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment #{env} does not exist"
        end
        mykey = Key[:name => key, :app_id => myapp[:id]]
        # New one, let's create
        if mykey.nil?
            response.status = 404
            return "Environment #{env} does not exist"
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

    def createEnv(env)
        msg = nil
        if not env =~ /\A[.a-zA-Z0-9_-]+\Z/
            response.status = 403
            msg = "Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        elsif Environment[:name => env]
            response.status = 403
            msg = "Environment already exists."
        else
            Environment.create(:name => env)
            response.status = 201
            msg = "Environment created."
        end
        return msg
    end

    def createApp(env, app)
        if not app =~ /\A[.a-zA-Z0-9_-]+\Z/
            response.status = 403
            return "Invalid application name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        end

        myapp = App[:name => app]
        myenv = Environment[:name => env]

        if myenv.nil?
            response.status = 404
            return "Environment #{env} does not exist"
        end

        owner = request['owner']
        if owner.nil?
            myowner = Owner[:name => "nobody"]
        else
            myowner = Owner[:name => owner]
            if myowner.nil?
                response.status = 404 if myowner.nil?
                return "Unknown owner..."
            end
        end

        if myapp.nil?
            defaultenv = Environment[:name => 'default']
            myapp = App.create(:name => app)
            myapp.add_environment(defaultenv)
            OwnerAppEnv.create(:app_id => myapp[:id], :environment_id => defaultenv[:id], :owner_id => Owner[:name => "nobody"][:id])

            response.status = 201
        end

        if env != 'default'
            myapp.add_environment(myenv)
                
            curowner = OwnerAppEnv[:app_id => myapp[:id], :environment_id => myenv[:id]]
            if curowner.nil?
                OwnerAppEnv.create(:app_id => myapp[:id], :environment_id => myenv[:id], :owner_id => myowner[:id])
            else
                curowner.update(:owner_id => myowner[:id])
                response.status = 200
            end
        end
    end

    def setValue(env, app, key)
        if not key =~ /\A[.a-zA-Z0-9_-]+\Z/
            response.status = 403
            return "Invalid key name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        end

        value = request.body.read
        myapp = App[:name => app]
        if myapp.nil?
            response.status = 404
            return "App #{app} does not exist"
        end
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment #{env} does not exist"
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
