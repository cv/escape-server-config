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
require 'digest/md5'

class UserController < EscController
    map('/user')

    def index(name = nil)
        # Sanity check what we've got first
        if name && (not name =~ /\A[.a-zA-Z0-9_-]+\Z/)
            respond("Invalid user name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403)
        end

        @name = name

        # Getting...
        if request.get?
            if name.nil?
                list_all_users
            else
                get_userDetails
            end

        # Posting...
        elsif request.post?
            createUpdateUser

        # Deleting...
        elsif request.delete?
            deleteUser

        # Not defined...
        else
            respond("Undefined", 400)
        end
    end

    private

    def list_all_users
        response.headers["Content-Type"] = "application/json"

        data = []
        Owner.all.each do |user|
            data.push(user.name)
        end

        return data.sort.to_json
    end

    def get_user(fail_on_error = true)
        respond("Undefined", 400) if @name.nil?

        @user = Owner[:name => @name]

        if fail_on_error and not @user
            respond("User #{@name} not found", 404)
        end
    end

    def get_userDetails
        get_user

        response.headers["Content-Type"] = "application/json"
        data = {}
        data["name"] = @user.name
        data["email"] = @user.email
        return data.to_json
    end

    def createUpdateUser
        get_user(false)

        email = request["email"] rescue nil
        password = Digest::MD5.hexdigest(request["password"]) rescue nil

        # No such user, we're creating...
        if @user.nil?
            respond("email missing", 403) if email.nil?
            respond("password missing", 403) if password.nil?

            begin
                Owner.create(:name => @name, :email => email, :password => password)
                respond("Created user #{@name}", 201)
            rescue
                respond("Error creating user. Does it already exist?", 403)
            end
        # User exists, we're updating
        else
            check_user_auth
            @user.update(:email => email) unless email.nil?
            @user.update(:password => password) unless password.nil?
        end
    end

    def deleteUser
        get_user

        check_user_auth
        @user.environments.each do |env|
            env.owner_id = 1
        end
        @user.remove_all_environments
        @user.delete
        respond("User #{@name} deleted", 200)
    end

end
