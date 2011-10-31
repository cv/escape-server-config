#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
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
