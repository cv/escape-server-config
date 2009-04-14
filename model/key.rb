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

class Key < Sequel::Model(:keys)
    many_to_one :app, :class => :App
    one_to_many :values, :class => :Value

    set_schema do
        primary_key :id, :null => false
        String :name

        foreign_key :app_id, :table => :apps, :type => Integer
    end
end

EscData.init_model(Key)

