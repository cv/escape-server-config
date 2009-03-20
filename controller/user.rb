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
require 'md5'

class UserController < EscController
    map('/user')

    def index(name = nil)
        # Sanity check what we've got first
        if name && (not name =~ /\A[.a-zA-Z0-9_-]+\Z/)
            respond "Invalid user name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403
        end

        # Undefined
        if name.nil?
            respond "Undefined", 400
        end

        # Getting...
        if request.get?
            getUser(name)

        # Posting...
        elsif request.post?
            createUpdateUser(name)

        elsif request.delete?
            deleteUser(name)

        # Not defined
        else
            response.status = 400
        end
    end

    private

    def getUser(name)
        user = Owner[:name => name]

        if not user
            response.status = 404
            return "User #{name} not found"
        else
            response.headers["Content-Type"] = "application/json"
            data = {}
            data["name"] = user.name
            data["email"] = user.email
            return data.to_json
        end
    end

    def createUpdateUser(name)
        user = Owner[:name => name]

        email = request["email"] rescue nil
        password = MD5.hexdigest(request["password"]) rescue nil

        # No such user, we're creating...
        if user.nil?
            if email.nil?
                response.status = 403
                return "email missing"
            end

            if password.nil?
                response.status = 403
                return "password missing"
            end

            begin
                Owner.create(:name => name, :email => email, :password => password)
                response.status = 201
            rescue 
                response.status = 403
                return "Error creating user. Does it already exist?"
            end
        # User exists, we're updating
        else
            check_auth(name)
            if not email.nil?
                user.update(:email => email)
            end
            if not password.nil?
                user.update(:password => password) 
            end
        end
    end

    def deleteUser(name)
        user = Owner[:name => name]
        
        if user.nil?
            respond "User #{name} not found", 404
        else
            check_auth(name)
            user.environments.each do |env|
                env.owner_id = 1
            end
            user.remove_all_environments
            user.delete
            respond "User #{name} deleted", 200
        end
    end

end
