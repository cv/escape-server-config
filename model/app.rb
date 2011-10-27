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

class App < Sequel::Model(:apps)
    plugin :validation_class_methods
    plugin :schema
    plugin :hook_class_methods

    many_to_many :environments, :class => :Environment
    one_to_many :keys, :class => :Key

    set_schema do
        primary_key :id, :null => false
        String :name
    end

    validates_uniqueness_of :name

    after_create do |app|
        app.add_environment(Environment[:name => 'default'])
    end

    def get_key_value(key, env)
      return nil if key.nil?
      value = Value[:key_id => key[:id], :environment_id => env[:id]]
      if value.nil?
          value = Value[:key_id => key[:id], :environment_id => Environment.default[:id]]
      end
      value
    end

    def set_key_value(key, env, value, encrypted)
       myKey = Key[:name => key, :app_id => self[:id]]
        # New one, let's create
        if myKey.nil?
            myKey = Key.create(:name => key, :app_id => self[:id])
            self.add_key(myKey)
            Value.create(:key_id => myKey[:id], :environment_id => Environment.default[:id], :value => value, :is_encrypted => encrypted)
            Value.create(:key_id => myKey[:id], :environment_id => env[:id], :value => value, :is_encrypted => encrypted)
            true
        # We're updating the config
        else
            myValue = Value[:key_id => myKey[:id], :environment_id => env[:id]]
            if myValue.nil? # New value...
                Value.create(:key_id => myKey[:id], :environment_id => env[:id], :value => value, :is_encrypted => encrypted)
                true
            else # Updating the value
                myValue.update(:value => value, :is_encrypted => encrypted)
                false
            end
        end
    end
end

EscData.init_model(App)

