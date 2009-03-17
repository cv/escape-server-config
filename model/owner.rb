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

class Owner < Sequel::Model(:owners)
    one_to_many :environments

    set_schema do
        primary_key :id, :null => false
        String :name
        String :email
        String :password
    end
    
    validates_uniqueness_of :name
    validates_uniqueness_of :email
end

EscData.init_model(Owner)

if Owner[:name => 'nobody'].nil?
    nobody = Owner.create(:name => 'nobody', :email => 'nobody@nowhere.com', :password => 'nothing')
    nobody.add_environment(Environment[:name => 'default'])
end

