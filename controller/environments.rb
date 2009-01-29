
class EnvironmentsController < Ramaze::Controller

    def index(env = nil, app = nil, key = nil)
        # Getting...
        if request.get?
            # List all environments
            if env.nil?
                return Environment


            # List all apps in specified environment
            elsif app.nil?
                myenv = Environment[:name => env]
                if myenv.nil?
                    response.status = 404
                else
                    #apps = DB[:apps].where(:environment => myenv[:id])
                    apps = DB[:apps]
                    return apps.all
                end


            # List keys and values for app in environment
            elsif key.nil?
                myenv = Environment[:name => env]
                if myenv.nil? # Env does not exist
                    response.status = 404
                else
                    apps = App[:environment => myenv[:id]]
                    if apps.nil?
                        response.status = 404
                    else
                        return apps.all
                    end
                end


            # We're getting value for specific key
            else 
                values = Value[:key => key, :app => App[:name => app][:id], :environment => Environment[:name => env][:id]]
                if values.nil? 
                    # Not in the specified env, is it in default?
                    values = Value[:key => key, :app => App[:name => app][:id], :environment => Environment[:name => "default"][:id]]
                    if values.nil?
                        response.status = 404
                    else
                        return values[:value]
                    end
                else
                    return values[:value]
                end
            end


        # Setting...
        elsif request.post? || request.put?
            # Undefined
            if env.nil?
                response.status = 400


            # You're putting an env
            elsif app.nil?
                begin
                    Environment.create(:name => env)
                    response.status = 201
                rescue
                    response.status = 403
                end


            # You're putting an app
            elsif key.nil?
                begin
                    App.create(:name => app, :environment => Environment[:name => env][:id])
                    response.status = 201
                rescue
                    response.status = 403
                end


            # You're putting a value to a key
            else             
                value = request.body.read
                myvalue = Value[:app => App[:name => app][:id], :environment => Environment[:name => env][:id], :key => key]
                # New one, let's create
                if myvalue.nil?
                    Value.create(:key => key, :value => value, :app => App[:name => app][:id], :environment => Environment[:name => env][:id])
                    response.status = 201
                # We're updating the config
                else             
                    myvalue.update(:value => value)
                    response.status = 200
                end
            end
        end
    end
end
