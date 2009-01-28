
class EnvironmentsController < Ramaze::Controller
    map('/environments')

    def index(env = nil, app = nil, key = nil)
        if request.get?
            envs = DB[:environments]
            if env == nil # List environments
                return envs.all
            else
                myenv = envs.where(:name => env)
                if myenv.empty? # Env does not exist
                    response.status = 404
                else
                    apps = DB[:apps]
                    return apps.all
                end
            end
        elsif request.put?
            p "We're putting..."
            if env == nil
                p "No env specified - where do we put it?"
                response.status = 400
            else
                p "Creating new app #{app} in environment #{env}"
                begin
                    myapp = App.new(:name => app)
                    p " - Made the app"
                    myapp.save
                    p " - Saved the app"
                    response.status = 201
                rescue
                    p " - Something exploded"
                    response.status = 403
                end
            end
        elsif request.post?
            'post me'
        end
    end
end
