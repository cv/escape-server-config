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

class AppsEnvironments < Sequel::Model
    set_schema do
        Integer :app_id
        Integer :environment_id
    end
end

EscData.init_model(AppsEnvironments)

class AppsKeys < Sequel::Model
    set_schema do
        Integer :app_id
        Integer :key_id
    end
end

EscData.init_model(AppsKeys)

class OwnerAppEnv < Sequel::Model
    set_schema do
        primary_key :id, :null => false
        Integer :app_id
        Integer :environment_id
        Integer :owner_id
    end

    validates_uniqueness_of([:app_id, :environment_id])
end

EscData.init_model(OwnerAppEnv)

