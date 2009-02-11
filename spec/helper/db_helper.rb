
require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('../../start')

module DBHelper
    def reset_db
        App.create_table!
        Environment.create_table!
        Owner.create_table!
        Key.create_table!
        Value.create_table!
        AppsEnvironments.create_table!
        AppsKeys.create_table!
        OwnerAppEnv.create_table!

        if Owner[:name => 'nobody'].nil?
            Owner.create(:name => 'nobody', :email => 'nobody@nowhere.com', :password => 'nothing')
        end

        if Environment[:name => 'default'].nil?
            Environment.create(:name => 'default')
        end
    end

end

shared "db_helper" do
    extend DBHelper
end
