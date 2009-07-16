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

class Environment < Sequel::Model(:environments)
    plugin :validation_class_methods
    plugin :schema
    plugin :hook_class_methods

    many_to_many :apps, :class => :App
    many_to_one :owner, :class => :Owner
    one_to_many :values, :class => :Value

    set_schema do
        primary_key :id, :null => false
        String :name
        String :public_key, :size => 2048
        String :private_key, :size => 2048

        foreign_key :owner_id, :table => :owners, :type => Integer
    end

    validates_uniqueness_of :name

    before_create do |env|
        env.owner_id = 1
    end
    
    def self.default
      Environment[:name => "default"]
    end
end

EscData.init_model(Environment)

if Environment[:name => 'default'].nil?
    Environment.create(:name => 'default')
end

