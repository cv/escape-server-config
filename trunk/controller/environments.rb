
class EnvironmentsController < Ramaze::Controller
    map('/environments')

    def index(env = nil, app = nil, key = nil)
        if request.get?
            envs = DB[:environments]
            if env == nil # List environments
                return envs.all
            elsif key == nil # List
                myenv = envs.where(:name => env)
                if myenv.empty? # Env does not exist
                    response.status = 404
                else
                    apps = DB[:apps]
                    return apps.all
                end
            else
                values = DB[:values].where(:key => key, :app => App[:name => app][:id], :environment => Environment[:name => env][:id])
                if values.empty? 
                    # Not in the specified env, is it in default?
                    values = DB[:values].where(:key => key, :app => App[:name => app][:id], :environment => Environment[:name => "default"][:id])
                    
                    if values.empty?
                        response.status = 404
                    else
                        return values.first[:value]
                    end
                else
                    return values.first[:value]
                end
            end
        elsif request.post? || request.put?
            if env == nil # Undefined
                response.status = 400
            elsif app == nil # You're putting an env
                begin
                    myenv = Environment.create(:name => env)
                    response.status = 201
                rescue
                    response.status = 403
                end
            elsif key == nil # You're putting an app
                begin
                    myapp = App.create(:name => app)
                    response.status = 201
                rescue
                    response.status = 403
                end
            else             # You're putting a value to a key
                value = request.body.read
                values = DB[:values].where(:app => App[:name => app][:id], :environment => Environment[:name => env][:id], :key => key)
                if values.empty? # New one, let's create
                    myvalue = Value.create(:key => key, :value => value, :app => App[:name => app][:id], :environment => Environment[:name => env][:id])
                    response.status = 201
                else             # We're updating the config
                    p " Updating key #{key} to value #{value}"
                    myvalue = values.first
                    Value.update(myvalue.update(:value => value))
                    response.status = 200
                end
            end
        end
    end
end
