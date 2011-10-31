require 'rubygems'
require 'bundler/setup'

require 'ramaze'
require 'ramaze/spec/bacon'

require __DIR__('helper/db_helper')
require __DIR__('../start')

# compatibility between RSpec 1.x and Bacon

def behaves_like(*whatever)
  include Rack::Test::Methods
  include DBHelper
end

def app
  Ramaze.middleware
end
