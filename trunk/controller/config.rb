
class ConfigController < Ramaze::Controller
    def index(app = nil, env = nil, key = nil)
        if request.get?
            ''
        elsif request.put?
            'put me'
        elsif request.post?
            'post me'
        end
    end
end
