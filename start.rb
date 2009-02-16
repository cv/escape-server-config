#!/usr/bin/env ruby
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
gem 'ramaze', '>=2009.01'
require 'ramaze'
gem 'mongrel', '>=1.1.5'
require 'mongrel'

# Add directory start.rb is in to the load path, so you can run the app from
# any other working path
$LOAD_PATH.unshift(__DIR__)

EscapeVersion = 0.2

# Initialize controllers and models
require 'model/init'
require 'controller/init'

Ramaze.start :adapter => :mongrel, :port => 7000
