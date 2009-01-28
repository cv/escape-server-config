
class EnvironmentsController < Ramaze::Controller
    map('/environments')

    def index(env = nil, app = nil, key = nil)
        if request.get?
            envs = DB[:environments]
            if env == nil # List environments
                return envs.all
            elsif key == nil
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
                    response.status = 404
                else
                    return values.first[:value]
                end
            end
        elsif request.post? || request.put?
            if env == nil
                response.status = 400
            elsif key == nil
                begin
                    myapp = App.new(:name => app)
                    myapp.save
                    response.status = 201
                rescue
                    response.status = 403
                end
            else
                value = request.body.read
                values = DB[:values].where(:app => app, :environment => env, :key => key)
                if values.empty? # New one, let's create
                    myvalue = Value.new(:key => key, :value => value, :app => App[:name => app][:id], :environment => Environment[:name => env][:id])
                    myvalue.save
                    response.status = 201
                else             # We're updating the config
                end
            end
        end
    end
end
