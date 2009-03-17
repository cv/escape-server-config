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

class OwnerController < EscController
    map('/owner')

    def index(env = nil)
        # Sanity check what we've got first
        if env && (not env =~ /\A[.a-zA-Z0-9_-]+\Z/)
            response.status = 403
            return "Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        end

        # Getting...
        if request.get?
            # Undefined
            if env.nil?
                response.status = 400
            else
                getOwner(env)
            end
        end
    end

    private

    def getOwner(env)
        myEnv = Environment[:name => env]
        
        if myEnv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist"
        end

        response.headers["Content-Type"] = "text/plain"   
        owner = Owner[:id => myEnv.owner_id]
        return owner.name
    end
    
end
