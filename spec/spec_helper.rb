require 'rubygems'
require 'bundler'
Bundler.require :default, :development

require File.join(File.dirname(__FILE__), '..', 'app')

RSpec.configure do

  include Rack::Test::Methods

  def app
    Ramaze.middleware
  end

  def reset_db
    App.create_table!
    Environment.create_table!
    Owner.create_table!
    Key.create_table!
    Value.create_table!
    AppsEnvironments.create_table!

    if Environment[:name => 'default'].nil?
      Environment.create :name => 'default'
    end

    if Owner[:name => 'nobody'].nil?
      nobody = Owner.create :name => 'nobody', :email => 'nobody@nowhere.com', :password => 'nothing'
      nobody.add_environment Environment[:name => 'default']
    end

  end

end
