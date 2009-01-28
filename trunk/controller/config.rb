
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
                if apps.where(:name => app).count == 0
                    response.status = 404
                end
            end
            return ret
        elsif request.put?
            if app == nil
                response.status = 501
            else
                myapp = App.new(:name => app)
                myapp.save
                response.status = 201
            end
        elsif request.post?
            'post me'
        end
    end
end
