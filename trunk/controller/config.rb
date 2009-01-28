
class ConfigController < Ramaze::Controller
    def index(app = nil, env = nil, key = nil)
        ret = ""
        if request.get?
            apps = DB[:apps]
            if app == nil
                apps.each { |app|
                    p app[:name]
                    ret += app[:name]
                }
            else
                myapp = apps.where(:name => app)
                if myapp.count == 0
                    response.status = 404
                else
                    envs = DB[:environments].where(:app => myapp.first)
                end
            end
            return ret
        elsif request.put?
            if app == nil
                response.status = 400
            else
                begin
                    myapp = App.new(:name => app)
                    myapp.save
                    response.status = 201
                rescue
                    response.status = 403
                end
            end
        elsif request.post?
            'post me'
        end
    end
end
