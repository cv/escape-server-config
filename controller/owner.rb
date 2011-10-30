# -*- encoding : utf-8 -*-
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

# This controller handles the specific owner of each given environment
class OwnerController < EscController
    map('/owner')

    def index(env = nil)
        # Sanity check what we've got first
        if env && (not env =~ /\A[.a-zA-Z0-9_-]+\Z/)
            respond("Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403)
        end

        # Undefined
        if env.nil?
            respond("Undefined", 400)
        end

        @env = env

        # Getting...
        if request.get?
            get_owner
        elsif request.post?
            set_owner
        elsif request.delete?
            clear_owner
        else
            respond("Undefined", 400)
        end
    end

    private

    def get_owner
        get_env

        owner = Owner[:id => @my_env.owner_id]

        response.headers["Content-Type"] = "text/plain"
        return owner.name
    end

    def set_owner
        if @env == "default"
            respond("No one can own the 'default' environment", 403)
        end

        get_env

        if @my_env.owner_id == 1
            #auth = check_auth(nil, "Environment #{@env}")
            auth = get_env_auth
        else
            auth = check_env_auth
        end

        owner = Owner[:name => auth]

        respond("Owner #{auth} not found", 404) if owner.nil?

        @my_env.owner = owner
        @my_env.save
        return "Owner of environment #{@env} is now #{auth}"
    end

    def clear_owner
        get_env

        if @my_env.owner_id == 1
            respond("Environment #{@env} is not owned by anyone", 200)
        else
            auth = check_env_auth
        end

        @my_env.owner = Owner[:name => "nobody"]
        @my_env.save
        return "Owner of environment #{@env} is now nobody"
    end

end
